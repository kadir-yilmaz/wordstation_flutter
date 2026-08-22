# 🛡️ Faz 10: Çoklu Platform Smart JWT ve In-Memory Token Mimarisi

Bu doküman; Flutter uygulamasının **tek bir Dart kod tabanı** ile Web, Mobil (iOS/Android) ve Masaüstü (Windows/Linux/macOS) platformlarında güvenlik standartlarına (OWASP) tam uyumlu, akıllı ve platforma duyarlı token yönetim mimarisini açıklar.

---

## 🛑 1. Web Güvenliği Problemi ve Neden Bu Mimari?

### Klasik Yaklaşımın Riski (LocalStorage):
* Mobilde `flutter_secure_storage` iOS Keychain ve Android Keystore gibi donanımsal çipleri kullanırken, **Web platformunda mecburen `window.localStorage` kullanır**.
* `localStorage`'a yazılan her veri JavaScript tarafından okunabilir. Sitede oluşabilecek en ufak bir **XSS (Cross-Site Scripting)** açığında veya 3. parti kütüphane sızıntısında saldırgan `access_token` ve `refresh_token`'ı saniyeler içinde çalabilir.

### 🏆 Çözüm: "In-Memory Access Token + HttpOnly Refresh Cookie"
* **Access Token:** Sadece **Dart RAM'inde (In-Memory)** tutulur. LocalStorage'a **ASLA** yazılmaz (0 XSS Riski).
* **Refresh Token:** Tarayıcının JavaScript'e kapalı **HttpOnly + Secure Cookie** alanında tutulur.
* **Mobil/Desktop:** Donanımsal kasalarında (`Keychain` / `EncryptedSharedPreferences` / `DPAPI`) güvenle çalışmaya devam eder.

---

## 🏗️ 2. Platformlar Arası Akıllı Ayrım Mimarisi

```text
                          ┌────────────────────────────────┐
                          │   Dart Auth / Storage Servisi  │
                          └───────────────┬────────────────┘
                                          │
                                          ▼
                                ┌───────────────────┐
                                │     kIsWeb ?      │
                                └─────────┬─────────┘
                     ┌────────────────────┴────────────────────┐
                     │ EVET                                    │ HAYIR
                     ▼ (Web Platformu)                         ▼ (iOS, Android, Masaüstü)
       ┌───────────────────────────────┐         ┌───────────────────────────────┐
       │         Web Stratejisi        │         │        Native Stratejisi      │
       ├───────────────────────────────┤         ├───────────────────────────────┤
       │ 🔑 Access Token:              │         │ 🔐 Depolama:                  │
       │    Dart RAM (In-Memory)       │         │    FlutterSecureStorage       │
       │                               │         │                               │
       │ 🍪 Refresh Token:             │         │ 🛡️ Donanımsal Kasalar:        │
       │    HttpOnly + Secure Cookie   │         │    • iOS Keychain             │
       │                               │         │    • Android EncryptedPrefs   │
       │ 🧹 LocalStorage:              │         │    • Windows DPAPI / Mac Keyc.│
       │    0 Token (XSS'e %100 Bağışık)│        │                               │
       │                               │         │ 💾 Access & Refresh Token:    │
       │ 🔄 Sayfa Yenilendiğinde (F5): │         │    Şifreli Donanımsal Kasada  │
       │    Silent Refresh Devreye Girer│        └───────────────────────────────┘
       └───────────────────────────────┘
```

---

## 🔄 3. Web'de Oturum ve Sessiz Kurtarma (Silent Refresh) Akışı

```text
┌─────────────────────────────────┐                       ┌─────────────────────────────────┐
│     Flutter Web (Tarayıcı/RAM)  │                       │   Backend API (.NET / IIS)      │
└────────────────┬────────────────┘                       └────────────────┬────────────────┘
                 │                                                         │
                 │ ── 1. POST /api/auth/login (withCredentials: true) ───> │
                 │ <── 2. 200 OK + Body: { accessToken } ───────────────── │
                 │        Set-Cookie: refreshToken (HttpOnly, Secure)      │
  [ RAM'e Yazılır: accessToken ]                                           │
  [ LocalStorage: BOMBOŞ ]                                                 │
                 │                                                         │
                 │ ── 3. GET /api/words (Authorization: Bearer token) ───> │
                 │ <── 4. 200 OK (Kelimeler & Veriler) ─────────────────── │
                 │                                                         │
─────────────────┴─── 🔄 SAYFA YENİLENDİ (F5) / YENİ SEKME AÇILDI ────────┴──────────────────
  [ RAM Sıfırlandı: token == null ]                                        │
                 │                                                         │
                 │ ── 5. POST /api/auth/refresh-token (Cookie Otomatik) ─> │
                 │ <── 6. 200 OK + Body: { newAccessToken } ────────────── │
  [ RAM Yenilendi: newAccessToken ]                                        │
  [ Kullanıcı Kesintisiz Devam Eder ]                                      │
                 │                                                         │
```

---

## 🧩 4. Katman Katman Uygulama Detayları

### A. Core Storage Katmanı (`SecureStorageService`)
* `kIsWeb` sabiti ile derleme zamanında platformu tanır.
* Web'de statik RAM değişkenleri (`_inMemoryAccessToken`, `_inMemoryUserId`, `_inMemoryUserEmail`) kullanır.
* `localStorage`'a hassas JWT token'ları yazılmaz; yalnızca tema tercihi gibi zararsız konfigürasyonlar kalır.
* `getRefreshToken()` Web'de `null` döner çünkü cookie'yi doğrudan tarayıcı yönetir.

### B. Core Network Katmanı (`ApiClient` & `AuthInterceptor`)
* `ApiClient`: Web ortamında (`kIsWeb`) `BaseOptions.extra['withCredentials'] = true` ekleyerek Cross-Origin cookie iletimini açar.
* `AuthInterceptor`:
  * `onRequest`: RAM'den (Web) veya kasadan (Native) okuduğu token'ı `Authorization: Bearer <token>` olarak ekler.
  * `onError (401)`: 
    * Web'de `withCredentials: true` ile cookie üzerinden refresh isteği atar.
    * Native'de kasadaki `refreshToken` string'i ile yeniler.
    * Dönen yeni token ile başarısız isteği otomatik ve şeffafça tekrarlar.

### C. Auth Service Katmanı (`AuthService`)
* `trySilentRefresh()`: Web'de sayfa açılışında arka planda sessiz oturum kurtarma yapar.
* `loginWithEmail`, `register`, `loginWithGoogle`, `logout`: Platform farkı gözetmeksizin aynı sade API ile çağrılır.

### D. Auth Controller Katmanı (`AuthController`)
* `checkAuthStatus()`:
  * Native'de kasayı kontrol eder.
  * Web'de RAM boşsa (F5 atılmışsa) `trySilentRefresh()` çağırarak kullanıcıyı login ekranına düşürmeden oturumu canlandırır.

---

## 📊 5. Platform Güvenlik ve Depolama Karşılaştırması

| Kriter | Mobil (iOS & Android) | Masaüstü (Windows, macOS, Linux) | Web (Chrome, Edge, Safari, Firefox) |
|---|---|---|---|
| **Access Token Konumu** | Keychain / EncryptedSharedPrefs | DPAPI / SecretService / Keychain | **Dart In-Memory (RAM)** |
| **Refresh Token Konumu** | Keychain / EncryptedSharedPrefs | DPAPI / SecretService / Keychain | **HttpOnly + Secure Cookie** |
| **LocalStorage Kullanımı** | Yok | Yok | **Sıfır Token (Temiz)** |
| **XSS Dayanıklılığı** | Güvenli | Güvenli | **%100 Bağışık** |
| **CSRF Koruması** | Bearer Header | Bearer Header | **Bearer Header + SameSite Cookie** |
| **Sayfa Yenileme (F5)** | N/A | N/A | **Silent Refresh ile Kesintisiz** |
| **Dart Kod Tabanı** | **Tek Kod Tabanı** | **Tek Kod Tabanı** | **Tek Kod Tabanı** |
