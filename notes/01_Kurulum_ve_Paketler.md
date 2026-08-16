# 📦 Faz 1: Kurulum ve Paket Yapılandırmaları

WordStation Flutter projesinin bağımlılıkları, platform ayarları ve temel yapılandırmaları tamamlanmıştır.

## 1. Eklenen Paketler (`pubspec.yaml`)
- **`flutter_riverpod` (^2.6.1):** Reaktif ve tip güvenli durum yönetimi (MVVM).
- **`dio` (^5.11.0):** HTTP istemcisi ve `QueuedInterceptorsWrapper` ile 401 otomatik token yenileme.
- **`flutter_secure_storage` (^11.0.0):** iOS Keychain ve Android EncryptedSharedPreferences güvenli depolama.
- **`google_sign_in` (^7.2.0):** Resmi Google OAuth 2.0 kimlik doğrulama.
- **`flutter_tts` (^4.2.5):** İngilizce (en-US) kelime seslendirme motoru.
- **`lottie` (^3.5.1):** Akıcı vektörel animasyonlar.
- **`google_fonts` (^8.2.1):** Modern ve şık tipografi (Inter, Outfit).

## 2. iOS Yapılandırması (`ios/Runner/Info.plist`)
- `GIDClientID`: `276618571409-ssancomdsfpbnbtp3nvvh1om3iv4odqm.apps.googleusercontent.com`
- `CFBundleURLTypes` -> `CFBundleURLSchemes`: `com.googleusercontent.apps.276618571409-ssancomdsfpbnbtp3nvvh1om3iv4odqm`

## 3. Android Yapılandırması (`android/app/src/main/AndroidManifest.xml`)
- `android.permission.INTERNET` izni eklendi.
