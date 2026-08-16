# WordStation Flutter

WordStation, kullanıcıların kelime öğrenme, ezberleme ve pratik yapma süreçlerini yönetmelerini sağlayan çoklu platform (iOS, Android, macOS ve Web) destekli bir Flutter uygulamasıdır.

---

## Genel Bakış

WordStation; modern mimari prensipleri, durum yönetimi (State Management), güvenli kimlik doğrulama akışları ve tüm ekran boyutlarına uyum sağlayan responsive arayüz yapısı ile geliştirilmiştir.

---

## Desteklenen Platformlar

- Android
- iOS
- macOS
- Web

---

## Temel Özellikler

- **Çoklu Platform Kimlik Doğrulama:**
  - iOS, Android, macOS ve Web ortamlarında kesintisiz Google Sign-In (OAuth 2.0) desteği.
  - E-posta ve şifre ile standart kayıt ve giriş mekanizması.
  - JWT tabanlı token doğrulama ve güvenli oturum yönetimi.

- **Responsive ve Adaptif Arayüz:**
  - Ekran çözünürlüğüne ve cihaz tipine göre otomatik uyarlanan responsive tasarım.
  - Mobil cihazlarda alt navigasyon barı (BottomNavigationBar), geniş ekranlarda ve masaüstünde yan menü (Desktop Sidebar).
  - Sabit eksen yüksekliği (`mainAxisExtent`) ve taşma korumaları ile boyutlandırma hatalarını (Overflow) engelleyen esnek grid yapıları.

- **Kelime ve Çalışma Yönetimi:**
  - Kelime listesi görüntüleme, arama ve filtreleme.
  - Yeni kelime ve detay ekleme, düzenleme ve silme.
  - Flashcard ve sesli telaffuz (Text-to-Speech / TTS) destekli çalışma seansları (Study Session).
  - Eş anlamlılar ve örnek cümle inceleme modülü.

- **Quiz ve Değerlendirme:**
  - Çoktan seçmeli ve pratik odaklı kelime testleri.
  - Anlık skor ve performans takibi.

- **Profil ve Tema Desteği:**
  - Kullanıcı profil yönetimi ve hesap ayarları.
  - Dinamik Aydınlık (Light) ve Karanlık (Dark) tema geçişi.

---

## Kullanılan Paketler ve Bağımlılıklar

Uygulamada kullanılan kütüphaneler, sürümleri ve projedeki kullanım amaçları aşağıda detaylandırılmıştır:

### Temel Bağımlılıklar (Dependencies)

| Paket | Sürüm | Kullanım Amacı |
| :--- | :--- | :--- |
| **flutter_riverpod** | ^2.6.1 | Tip güvenli ve reaktif durum yönetimi (State Management), Controller ve Provider mimarisi. |
| **dio** | ^5.11.0 | REST API iletişimi, özel `AuthInterceptor` ile otomatik Bearer token ekleme ve ağ istek yönetimi. |
| **flutter_secure_storage** | ^9.2.2 | JWT token'ları ve hassas oturum verilerinin cihazın güvenli donanımında (iOS Keychain, Android EncryptedSharedPreferences) şifrelenerek saklanması. |
| **google_sign_in** | ^6.2.2 | Android, iOS, macOS ve Web üzerinde Google OAuth 2.0 ile tek tıkla kimlik doğrulama. |
| **flutter_tts** | ^4.2.5 | Kelimelerin doğru telaffuzunu dinletmek için kullanılan Text-to-Speech (metin seslendirme) motoru. |
| **audioplayers** | ^6.1.0 | Quiz ve çalışma seanslarında geri bildirim ve ses efektlerinin oynatılması. |
| **lottie** | ^3.5.1 | Başarı, kutlama, yüklenme ve boş durum (Empty State) ekranlarında kullanılan hafif vektörel animasyonlar. |
| **google_fonts** | ^8.2.1 | Modern ve okunabilir yazı tiplerinin (Inter vb.) dinamik yüklenmesi ve tipografi yönetimi. |
| **cupertino_icons** | ^1.0.8 | iOS tasarım çizgisine uygun simge seti desteği. |

### Geliştirici Bağımlılıkları (Dev Dependencies)

| Paket | Sürüm | Kullanım Amacı |
| :--- | :--- | :--- |
| **flutter_test** | SDK | Birim (Unit) ve widget test altyapısı. |
| **flutter_lints** | ^6.0.0 | Flutter ve Dart kod standartlarına, kurallarına ve temiz kod prensiplerine uygunluk analizi. |

---

## Platform Bazlı Google OAuth Mimarisi

Uygulama, her platformun kendi güvenlik ve SDK dinamiklerine uygun şekilde yapılandırılmıştır:

1. **Android:**
   - Google Play Services altyapısı üzerinden çalışır.
   - SHA-1 parmak izi ve paket adı eşleştirmesi ile doğrudan `idToken` alınır.

2. **iOS:**
   - Native Google Sign-In SDK ve `GIDSignIn` framework'ü kullanılır.
   - `Info.plist` üzerinde URL Scheme ve Reverse Client ID tanımları ile yapılandırılmıştır.

3. **macOS:**
   - macOS Sandbox ve Keychain erişim gereksinimlerine uygun olarak düzenlenmiştir.
   - `DebugProfile.entitlements` ve `Release.entitlements` dosyalarında `keychain-access-groups` yetkilendirmesi tanımlanmıştır.

4. **Web:**
   - Google Identity Services (GIS) JavaScript SDK'sı üzerinden popup akışı ile çalışır.
   - Profil bilgilerinin (isim, avatar vb.) istemci tarafında eksiksiz çekilebilmesi için Google People API entegrasyonu ile desteklenmiştir.
   - `kIsWeb` kontrolleri ile platforma özgü kütüphane çakışmaları engellenmiştir.

---

## Responsive Tasarım İlkeleri

- **Ekran Boyutu Yönetimi:** `ResponsiveLayout` ve `ResponsiveContent` bileşenleri ile içerik genişliği masaüstü ekranlarda dengelenir (maksimum içerik genişliği sınırlandırması).
- **Taşma (Overflow) Önleme:** Grid listelerinde oran tabanlı `childAspectRatio` yerine piksel garantili `mainAxisExtent` kullanılarak metin sığmama ve taşma hataları önlenmiştir.
- **Navigasyon Geçişleri:** Geniş ekranlarda (`width >= 720px`) sol dikey menüye, mobil ekranlarda alt menü çubuğuna otomatik geçiş sağlanır.

---

## Proje Dizin Yapısı

Proje, özellik odaklı (Feature-First) ve katmanlı mimariye uygun olarak organize edilmiştir:

```text
lib/
├── core/
│   ├── constants/       # Sabitler ve API uç noktaları
│   ├── network/         # Dio istemcisi, interceptor ve ağ servisleri
│   ├── services/        # TTS ve yardımcı servisler
│   ├── storage/         # Güvenli yerel veri depolama
│   ├── theme/           # Açık/koyu tema tanımları ve tema denetleyicisi
│   └── widgets/         # Yeniden kullanılabilir ve responsive ortak bileşenler
│
├── features/
│   ├── auth/            # Giriş, kayıt ve oturum yönetimi ekranları/denetleyicileri
│   ├── navigation/      # Adaptif ana navigasyon ve menü yönetimi
│   ├── profile/         # Kullanıcı profili ve ayarlar
│   ├── quiz/            # Sınav, test ve soru akışları
│   └── words/           # Kelime listeleri, çalışma seansları ve detay görünümleri
│
└── main.dart            # Uygulama başlangıç noktası ve ProviderScope tanımı
```

---

## Kurulum ve Çalıştırma

### Gereksinimler

- Flutter SDK (3.13.0 veya üzeri)
- Dart SDK
- Android Studio / Xcode / VS Code
- Chrome (Web geliştirme ve test için)

### Adımlar

1. **Depoyu klonlayın:**
   ```bash
   git clone <repository-url>
   cd wordstation_flutter
   ```

2. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

3. **Uygulamayı hedef platformda çalıştırın:**

   - **Android:**
     ```bash
     flutter run -d android
     ```

   - **iOS:**
     ```bash
     flutter run -d ios
     ```

   - **macOS:**
     ```bash
     flutter run -d macos
     ```

   - **Web (Sabit port ile):**
     ```bash
     flutter run -d chrome --web-port=52767
     ```
