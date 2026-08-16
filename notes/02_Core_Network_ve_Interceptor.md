# 🌐 Faz 2: Core Katmanı, Network ve Interceptor

Core katmanı tüm modern standartlar, Riverpod sağlayıcıları ve hata toleransı ile kurulmuştur.

## 1. Network & Auth Interceptor
- **`ApiConstants`:**
  - Base URL: `https://wsapi.runasp.net`
  - Auth: `/api/auth/login`, `/api/auth/register`, `/api/auth/google-login`, `/api/auth/refresh-token`, `/api/auth/revoke-token`
  - Words: `/api/words`, `/api/words/lists`, `/api/words/search`, `/api/words/synonym-groups`
- **`AuthInterceptor`:**
  - `QueuedInterceptorsWrapper` türetildi.
  - Her isteğe `Authorization: Bearer <accessToken>` otomatik eklenir.
  - `401 Unauthorized` hatasında kuyruğu bekletip temiz bir Dio ile `/api/auth/refresh-token` çağrısı yapar.
  - Yeni token'lar `SecureStorageService`'e kaydedilir, başarısız olan istek yeni token ile anında tekrarlanır.
  - Refresh başarısız olursa güvenli depolama temizlenir ve `unauthorizedEventProvider` tetiklenir.

## 2. Güvenli Depolama (`SecureStorageService`)
- iOS'te Keychain (`KeychainAccessibility.first_unlock`), Android'de `EncryptedSharedPreferences` kullanılır.
- `accessToken`, `refreshToken`, `userId`, `userEmail` ve `themeMode` anahtarları yönetilir.

## 3. Tema Sistemi & Renk Paleti (`AppColors`, `AppTheme`, `ThemeController`)
- **Turkuaz:** `#12C6B2` (Ana vurgu & Çalışma ön yüzü)
- **Pembe:** `#E3719D` (İkincil vurgu & Çalışma arka yüzü)
- **Turuncu:** `#FF9500` (Rastgele butonu)
- **Mavi:** `#007AFF` (TTS telaffuz hoparlörü)
- Google Fonts (`Inter` & `Outfit`) ile modern açık & koyu tema desteği.

## 4. Ortak Bileşenler
- `CustomButton`: Gradient, dokunsal geri bildirim (`HapticFeedback`), spinner ve ikon desteği.
- `CustomTextField`: Şık kenarlıklar, prefix/suffix ikonlar ve şifre gizleme/gösterme.
- `LoadingOverlay`: Şeffaf arkaplanlı yükleme penceresi.
- `EmptyStateView`: Boş liste ve sonuç bulunamadı görünümleri.
