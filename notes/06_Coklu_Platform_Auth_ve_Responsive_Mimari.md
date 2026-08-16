# 🌐 Çoklu Platform Kimlik Doğrulama (OAuth 2.0) ve Responsive Mimari Rehberi

Bu belge; WordStation projesinde **iOS, macOS, Android, Web ve .NET MVC Backend** platformları arasındaki kimlik doğrulama farklılıklarını, karşılaşılan kritik hataların çözümlerini ve **Responsive (Masaüstü/Mobil uyumlu)** tasarım mimarisini derinlemesine açıklamaktadır.

---

## 📌 BÖLÜM 1: Platformlar Arası Google OAuth 2.0 Çalışma Mantığı

Google ile oturum açma işlemi her platformda aynı görünse de arka plandaki güvenlik ve veri çekme mekanizmaları platforma göre köklü farklılıklar gösterir.

### 1. ⚙️ .NET MVC & ASP.NET Core Backend (Server-Side Flow)
* **Akış Türü:** *OAuth 2.0 Authorization Code Flow*
* **Çalışma Prensibi:**
  1. Kullanıcı Google üzerinde oturum açtığında Google sunucuları doğrudan .NET sunucunuza kriptografik olarak imzalanmış bir **`id_token` (JWT)** gönderir.
  2. .NET middleware'i bu JWT'nin imzasını doğrular ve token'ın içerisindeki **Claims (Kullanıcı Bilgileri)** nesnelerini çözer:
     ```json
     {
       "email": "kadir@example.com",
       "name": "Kadir Yılmaz",
       "picture": "https://lh3.googleusercontent.com/a/...",
       "sub": "google-user-id-12345"
     }
     ```
* **Neden People API Gerekmez?**
  Kullanıcının adı, e-postası ve profil fotoğrafı zaten imzalı token'ın içinde teslim edilir. Backend Google'a ekstra bir profil okuma isteği atmaz.

---

### 2. 📱 iOS & macOS (Native CocoaPod SDK)
* **Kullanılan Kütüphane:** `GoogleSignIn-iOS` (Objective-C / Swift)
* **Çalışma Prensibi:**
  - Safari View Controller veya dahili ASWebAuthenticationSession üzerinden çalışır.
  - Alınan OAuth token'ları yerel Apple Framework'ü tarafından çözülerek `GIDGoogleUser` nesnesi oluşturulur.
* **macOS Keychain Entitlement Kuralı (-34018 Hatası):**
  - macOS doğrudan bilgisayarın gerçek işletim sisteminde (Host OS) çalıştığı için Keychain'e token yazmak ister.
  - Apple, uygulamanın bir **Geliştirici Sertifikası (Apple ID / Personal Team)** ile imzalanmasını ve `keychain-access-groups` yetkilendirmesinin (`$(AppIdentifierPrefix)com.google.GIDSignIn`) eklenmiş olmasını şart koşar.

---

### 3. 🤖 Android (Google Play Services)
* **Kullanılan Kütüphane:** `com.google.android.gms.auth`
* **Çalışma Prensibi:**
  - Cihazdaki **Google Play Services** işletim sistemi seviyesinde çalışır.
  - Uygulamanın paket adı (`com.kadiryilmaz.wordstation_flutter`) ve **SHA-1 parmak izi** Google Cloud Console ile eşleştirilir.
  - Kullanıcı cihazdaki kayıtlı Google hesaplarından birini tek tıkla seçtiğinde `idToken` doğrudan Android OS tarafından üretilir.

---

### 4. 🌐 Flutter Web (`google_sign_in_web`)
* **Kullanılan Kütüphane:** Google Identity Services (GIS JavaScript SDK)
* **Çalışma Prensibi:**
  - Tarayıcıda JavaScript popup penceresi ile çalışır.
  - Kullanıcı popup'tan hesabını seçtiğinde tarayıcıya bir `access_token` döner.
  - Flutter'ın `google_sign_in_web` paketi, Dart tarafındaki `GoogleSignInAccount.displayName` ve `photoUrl` alanlarını doldurabilmek için arka planda Google'ın şu servisine REST isteği atar:
    > `GET https://people.googleapis.com/v1/people/me?sources=READ_SOURCE_TYPE_PROFILE`
* **Neden People API Şarttır?**
  Çünkü tarayıcıdaki açık kaynaklı Flutter Web kütüphanesi kullanıcı profilini client-side olarak bu REST servisinden çeker. Google Cloud Console'da **People API** kapalıysa `403 Permission Denied` hatası fırlatır.

---

## 📊 Platform Karşılaştırma Matrisi

| Platform | Çalışma Ortamı | Profil Bilgisi Kaynağı | People API Gerekli mi? | Özel Güvenlik Gereksinimi |
| :--- | :--- | :--- | :---: | :--- |
| **.NET MVC** | Sunucu (Server) | JWT `id_token` Claims | ❌ Hayır | Redirect URI (`/signin-google`) |
| **Android** | Android OS | Google Play Services | ❌ Hayır | SHA-1 Parmak İzi & Paket Adı |
| **iOS** | iOS Sandbox | GIDSignIn Framework | ❌ Hayır | URL Scheme / Reverse Client ID |
| **macOS** | Host OS Sandbox | GIDSignIn Framework | ❌ Hayır | Keychain Entitlement & Team ID |
| **Flutter Web** | Tarayıcı (Chrome) | **Google People API** | ✅ **EVET** | JS Origin (`http://localhost:port`) |

---

## 🛠️ BÖLÜM 2: Sık Karşılaşılan Hatalar ve Çözümleri

### 1. `Code: -34018, Message: A required entitlement isn't present` (macOS)
* **Sebep:** macOS uygulamasının Keychain paylaşım izninin olmaması ve imzasız (Ad-hoc) çalışması.
* **Çözüm:** 
  1. `macos/Runner.xcworkspace` projesini Xcode ile açın.
  2. **Runner -> Signing & Capabilities -> Team** menüsünden Apple ID / Personal Team seçin.
  3. `DebugProfile.entitlements` ve `Release.entitlements` içine `keychain-access-groups` (`$(AppIdentifierPrefix)com.google.GIDSignIn`) ekleyin.

### 2. `Unsupported operation: Platform._operatingSystem` (Flutter Web)
* **Sebep:** `dart:io` paketinin `Platform.isIOS` veya `Platform.operatingSystem` kontrollerinin Web'de desteklenmemesi.
* **Çözüm:** Her zaman önce `kIsWeb` kontrolü yapın:
  ```dart
  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'dart:io' show Platform;

  static String? get clientId {
    if (kIsWeb) return webClientId;
    return (Platform.isIOS || Platform.isMacOS) ? iosClientId : null;
  }
  ```

### 3. `Assertion failed: appClientId != null` (Flutter Web)
* **Sebep:** `web/index.html` içinde veya `GoogleSignIn` initialization sırasında Web Client ID verilmemesi.
* **Çözüm:** `web/index.html` içine meta etiketi ekleyin:
  ```html
  <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
  ```

### 4. `People API has not been used in project 403` (Flutter Web)
* **Sebep:** Google Cloud Console'da People API servisinin kapalı olması.
* **Çözüm:** Google Cloud Console -> **API Library** -> **People API** -> **ENABLE (Etkinleştir)** butonuna basın (Senkronizasyon ~2 dakika sürer).

---

## 🎨 BÖLÜM 3: Flutter Responsive Tasarım & Taşma (Overflow) Önleme

### 1. `BOTTOM OVERFLOWED BY X PIXELS` Neden Olur ve Nasıl Önlenir?
* **❌ Hatalı Yaklaşım (`childAspectRatio`):**
  `GridView` içinde `childAspectRatio: 2.8` verildiğinde ekran daraldıkça kartın dikey yüksekliği ~80px'e kadar küçülür ve içindeki 2 satır metin dışarı taşar.
* **✅ Doğru Yaklaşım (`mainAxisExtent`):**
  Oran yerine net piksel yüksekliği tanımlanır. Ekran ne kadar daralırsa daralsın kartın yüksekliği sabit kalır:
  ```dart
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    mainAxisExtent: 100, // Yükseklik her zaman 100px garantilidir!
  )
  ```

### 2. Metin Taşmalarına Karşı Güvenlik (`TextOverflow.ellipsis`)
```dart
Text(
  listName,
  maxLines: 1, // Asla 2. satıra kayıp alt widget'ı itmesin
  overflow: TextOverflow.ellipsis, // Sığmazsa '...' koysun
)
```

### 3. Masaüstü & Web İçin İçerik Sınırlandırması (`ResponsiveContent`)
Geniş ekranda butonların ve formların sonsuza kadar esnemesini engellemek için:
```dart
ResponsiveContent(
  maxWidth: 760, // Masaüstünde ideal orantı
  child: Column( ... ),
)
```

### 4. Navigasyon Adaptasyonu (Desktop Sidebar vs Mobile BottomBar)
* **Geniş Ekran (`width >= 720px`):** Alttaki menü gizlenir, sol tarafa dikey `DesktopSidebar` yerleştirilir.
* **Mobil Ekran (`width < 720px`):** Standart `BottomNavigationBar` kullanılır.

---

## ⚡ BÖLÜM 4: Geliştirme İpuçları (Sabit Port & CORS)

Flutter Web geliştirirken portun sürekli değişmesini engellemek ve API testlerini rahatça yapmak için:

1. **Sabit Port ile Başlatma:**
   ```bash
   flutter run -d chrome --web-port=52767 --web-browser-flag "--disable-web-security"
   ```
2. **Google Cloud Console Yetkili Kaynaklar:**
   - **Authorized JavaScript origins:** `http://localhost:52767`
   - **Authorized redirect URIs:** `http://localhost:52767/signin-google`
