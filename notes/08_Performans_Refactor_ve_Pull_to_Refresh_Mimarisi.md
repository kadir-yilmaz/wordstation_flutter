# 08 - Performans, Bellek Güvenliği, Refactor ve Pull-to-Refresh Mimarisi

Bu belgede WordStation uygulamasında kod kalitesini, bellek yönetimini (Memory Management), ağ verimliliğini ve kullanıcı deneyimini (UX) artırmak amacıyla gerçekleştirilen kapsamlı refactor ve optimizasyon çalışmaları detaylandırılmıştır.

---

## 1. Bellek Yönetimi ve Memory Leak Önleme

### Sorun: Dialog `TextEditingController` Sızıntıları
Flutter'da `TextEditingController`, `AnimationController` veya `ScrollController` gibi sınıflar doğrudan işletim sistemi native katmanında listener ve kanal (channel) kayıtları tutar. Bu nesneler widget ağacından kaldırıldığında otomatik olarak garbage collector tarafından temizlenmez; mutlaka `.dispose()` çağrısı yapılması gerekir.

* **Eski Durum:**
  `WordsListPage` (`_showAddListDialog`, `_showRenameDialog`) ve `AddEditWordPage` (`_showCreateListDialog`) metodlarında `final controller = TextEditingController();` fonksiyon gövdesinde tanımlanıyor ancak dialog kapandığında `dispose()` edilmiyordu. Bu durum, her liste oluşturma veya düzenleme işleminde bellekte çöp controller nesnelerinin birikmesine yol açıyordu.

* **Uygulanan Çözüm:**
  Dialog asenkron kapandıktan sonra `then` veya `try/finally` bloklarıyla controller nesnesinin güvenli bir şekilde dispose edilmesi sağlandı:
  ```dart
  void _showAddListDialog() {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(...),
    ).then((_) {
      textController.dispose(); // Bellek sızıntısı önlendi
      if (mounted) _isDialogOpen = false;
    });
  }
  ```

---

## 2. Ağ Trafiği Optimizasyonu (Over-fetching Önleme)

### Sorun: Sekme Geçişlerinde Gereksiz API İstekleri
* **Eski Durum:**
  `MainNavigationPage` içindeki `_onItemTapped` metodunda kullanıcı herhangi bir sekmeye (örneğin Quiz veya Profil) geçtiğinde `ref.read(wordListControllerProvider.notifier).refresh()` çağrısı koşulsuz olarak çalıştırılıyordu. Bu durum her sekme değişiminde sunucuya gereksiz kelime listesi istekleri atılmasına neden oluyordu.

* **Uygulanan Çözüm:**
  Ağ istekleri sadece ilgili sekmeye (Kelimelerim için `index == 0`, Eş Anlamlılar için `index == 1`) sınırlandırıldı:
  ```dart
  void _onItemTapped(int index) {
    if (_currentIndex == index && index == 0) {
      _myListsNavKey.currentState?.popUntil((route) => route.isFirst);
      ref.read(wordListControllerProvider.notifier).refresh();
    } else if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
      
      // Sadece ilgili sekmeye geçildiğinde veri tazele
      if (index == 0) {
        ref.read(wordListControllerProvider.notifier).refresh();
      } else if (index == 1) {
        ref.invalidate(synonymGroupsFutureProvider);
      }
    }
  }
  ```

---

## 3. Merkezi Hata Yönetimi (`DioErrorHandler`)

### Sorun: Mükerrer ve Tutarsız Hata Mesajları
* **Eski Durum:**
  `AuthService`, `WordService` ve `DailyQuizApiService` sınıflarında `_extractErrorMessage(DioException e)` fonksiyonu kopyala-yapıştır ile çoğaltılmıştı. Bazı servislerde ASP.NET ModelState (`errors`) validasyon mesajları çözümlenemiyor, kullanıcıya genel hatalar dönüyordu.

* **Uygulanan Çözüm:**
  `lib/core/network/dio_error_handler.dart` adında merkezi bir sınıf oluşturuldu:
  * Bağlantı zaman aşımı (`connectionTimeout`, `receiveTimeout`, `sendTimeout`)
  * Sunucu erişim hataları (`connectionError`)
  * .NET ModelState `errors` sözlüğü ve `detail`/`title`/`message` alanları
  * HTTP durum kodları (400, 401, 403, 404, 409, 500)
  tek bir merkezden standart ve anlaşılır Türkçe mesajlara dönüştürüldü. Tüm servisler bu sınıfa bağlandı.

---

## 4. Merkezi Text-to-Speech (TTS) Servisi (`TtsService`)

### Sorun: Dağınık TTS Başlatma ve Çakışmalar
* **Eski Durum:**
  Hem `StudyController` hem de `QuizPage` bağımsız `FlutterTts` nesneleri oluşturuyor ve iOS ses oturumu (`AVAudioSession`) konfigürasyonunu mükerrer şekilde yapıyordu. Bu durum eşzamanlı ses çalma denemelerinde platform kanalı kilitlenmelerine yol açabiliyordu.

* **Uygulanan Çözüm:**
  `lib/core/services/tts_service.dart` oluşturuldu ve Riverpod `ttsServiceProvider` üzerinden singleton olarak sağlandı:
  * iOS için `AVAudioSessionCategory.playback` ve `mixWithOthers` ayarları tek noktada yapıldı.
  * Oynatma durumunu takip eden `isPlaying` ve `isPlayingNotifier` mekanizması kuruldu.
  * `StudyController` ve `QuizPage` bu merkezi servisi kullanacak şekilde refactor edildi.

---

## 5. Mükerrer JWT Çözümleme Kodlarının Temizlenmesi (DRY)

* **Eski Durum:**
  `lib/core/utils/jwt_decoder.dart` yardımcı sınıfı projede bulunmasına rağmen, `SecureStorageService` içinde `_getUserIdFromJwt` ve `_getEmailFromJwt` adında regex ve manuel Base64 string bölme yapan fonksiyonlar tekrar yazılmıştı.
* **Uygulanan Çözüm:**
  `SecureStorageService` içindeki özel metodlar sadeleştirilerek doğrudan `JwtDecoder.decode(token)` çağrısına dönüştürüldü.

---

## 6. Global 401 (Unauthorized) Oturum Yönetimi

* **Eski Durum:**
  `AuthInterceptor` token süresi dolduğunda refresh token ile yenilemeyi dener; başarısız olursa `unauthorizedEventProvider` tetiklenirdi. `AuthController` oturum durumunu `unauthenticated` yapardı fakat arayüz seviyesinde kullanıcıyı otomatik olarak Login ekranına atan bir dinleyici yoktu.
* **Uygulanan Çözüm:**
  `MainNavigationPage` içerisine global `ref.listen<AuthState>` eklendi. Oturum düştüğünde kullanıcı mevcut gezinme geçmişi temizlenerek (`pushAndRemoveUntil`) güvenli bir şekilde `LoginPage` ekranına yönlendirilir.

---

## 7. Yukarıdan Aşağıya Kaydırarak Yenileme (Pull-to-Refresh)

Uygulamanın tüm ana ekranlarına modern ve akıcı `RefreshIndicator` desteği eklendi:

| Ekran | Dosya | Tetiklenen Eylem | Boş Durum Desteği |
|---|---|---|---|
| **Kelimelerim (My Lists)** | `words_list_page.dart` | `wordListControllerProvider.notifier.refresh()` | `LayoutBuilder` + `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics())` ile liste boşken de kaydırma aktif. |
| **Eş Anlamlılar** | `synonyms_page.dart` | `ref.invalidate(synonymGroupsFutureProvider)` | Liste doluyken veya arama sonucu boşken kaydırarak yenileme aktif. |
| **Kelime Testi (Quiz Yap)** | `quiz_page.dart` | Kelime listesi ve geçmişi sunucudan tazeleme | `AlwaysScrollableScrollPhysics` ile aktif. |
| **Günlük Quiz** | `quiz_page.dart` | Günlük plan, seri ve soru verilerini tazeleme | `AlwaysScrollableScrollPhysics` ile aktif. |
| **Quiz Geçmişi** | `quiz_history_page.dart` | `quizControllerProvider.notifier.loadInitialData()` | Boş ekranda ve liste doluyken kaydırarak yenileme aktif. |
| **Profil ve Ayarlar** | `profile_page.dart` | `profileControllerProvider.notifier.loadProfile()` | Profil ve istatistik kartlarını tazeleme. |

> **Kritik Flutter UX Kuralı:** `RefreshIndicator` altında bir widget'ın kaydırılabilir olabilmesi için `physics: AlwaysScrollableScrollPhysics()` ve scroll edilebilir bir view (`ListView` / `SingleChildScrollView`) gereklidir. Boş durumlar (`_buildEmptyState`) `LayoutBuilder` + `ConstrainedBox` ile sarılarak ekran boyutu kadar kaydırılabilir alan yaratılmış ve boşken dahi yenileme yapılabilmesi sağlanmıştır.

---

## 8. Linter ve Kod Kalitesi Doğrulaması

`analysis_options.yaml` dosyası modern Dart/Flutter en iyi pratikleriyle güçlendirildi:
* `avoid_print`
* `prefer_const_constructors`
* `prefer_const_declarations`
* `prefer_const_literals_to_create_immutables`
* `prefer_final_locals`
* `avoid_unnecessary_containers`
* `sized_box_for_whitespace`
* `use_build_context_synchronously`
* `cancel_subscriptions`
* `close_sinks`

### Analiz ve Test Sonuçları:
```bash
$ flutter analyze
Analyzing wordstation_flutter...
No issues found! (0 errors, 0 warnings)

$ flutter test
00:01 +13: All tests passed! (13/13 test başarılı)
```

---

## 9. Klavyenin UI'ı Yukarı İtmesini Engelleme (`resizeToAvoidBottomInset: false`)

### Sorun: Klavyenin UI Elemanlarını Yukarı Kaydırması / Sıkıştırması
Flutter'da varsayılan olarak `Scaffold` widget'ının `resizeToAvoidBottomInset` özelliği `true` değerine sahiptir. Bu nedenle kullanıcı bir arama çubuğuna (`TextField`) veya form kutusuna dokunduğunda:
* Klavye için yer açılabilmesi adına tüm sayfa (`body`) klavyenin yüksekliği kadar yukarı doğru sıkıştırılır / itilir.
* Bu durum çalışma kartlarının, başlıkların ve butonların yukarı doğru fırlamasına ve ekran düzeninin bozulmasına yol açar.

### Uygulanan Çözüm: `Scaffold(resizeToAvoidBottomInset: false)`
Sayfalardaki `Scaffold` yapılarına `resizeToAvoidBottomInset: false` parametresi eklendi:
* **Kelime Ekle / Düzenle (`AddEditWordPage`):** `resizeToAvoidBottomInset: false` ile form ve kaydet butonları sabit kalır, klavye doğrudan ekranın üzerine açılır.
* **Eş Anlamlılar (`SynonymsPage`):** Arama çubuğuna yazarken sayfa yukarı kaymaz, liste ve başlıklar yerinde sabit kalır; klavye ekranın alt kısmının üzerine bir katman (overlay) olarak biner.
* **Çalışma Seansı (`StudySessionPage`):** Arama yaparken çalışma kartı ve kontroller yukarı itilmez, stabil kalır.


