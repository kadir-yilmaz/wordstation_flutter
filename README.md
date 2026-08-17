# WordStation Flutter

WordStation, kullanıcıların kelime öğrenme, ezberleme ve pratik yapma süreçlerini yönetmelerini sağlayan çoklu platform destekli bir Flutter uygulamasıdır.

---

## Desteklenen Platformlar
(Not: Aşağıdaki tüm platformlar için google ile giriş desteği aktif edilmiştir. Çıktılar workflow ile alınıp test edilmiştir.)

- Android
- iOS
- Linux
- macOS
- Windows
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

