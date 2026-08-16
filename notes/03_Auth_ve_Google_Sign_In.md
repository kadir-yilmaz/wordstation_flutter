# 🔐 Faz 3: Kimlik Doğrulama ve Google Girişi

WordStation Flutter auth modülü tamamlandı.

## 1. Modeller & Servisler
- **Modeller:** `LoginRequest`, `TokenResponse`, `UserModel`.
- **`AuthService`:**
  - `loginWithEmail(email, password)`: `/api/auth/login` endpoint'i ile token alma ve kaydetme.
  - `register(email, password)`: `/api/auth/register` ile kayıt ve ardından otomatik giriş.
  - `loginWithGoogle()`: `GoogleSignIn` SDK tetikleme ve elde edilen `idToken`'ı `/api/auth/google-login` endpoint'ine iletip oturum açma.
  - `logout()`: `/api/auth/revoke-token` ve güvenli storage temizliği.

## 2. Durum Yönetimi (`AuthController`)
- `AuthState`: `initial`, `loading`, `authenticated`, `unauthenticated`, `error`.
- Interceptor'dan gelen 401 sinyali ile otomatik oturum sonlandırma.
- `checkAuthStatus()` ile Splash ekranında otomatik token kontrolü.

## 3. Ekranlar
- **`SplashPage`:** 1.2 saniyelik şık logo & pulse animasyonu ile token kontrolü ve sayfa geçişi.
- **`LoginPage`:** Swift `LoginVC` stiline sadık kalarak logo, e-posta/şifre alanları, Turkuaz giriş butonu, "veya" ayırıcı ve Google ile Giriş butonu.
- **`RegisterPage`:** Pembe tonlu şık kayıt formu ve şifre doğrulama kontrolleri.
