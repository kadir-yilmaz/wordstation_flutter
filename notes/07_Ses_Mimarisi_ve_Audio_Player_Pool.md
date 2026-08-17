# 07 - Flutter Cross-Platform Ses Mimarisi ve Audio Player Pool

Bu belgede, WordStation mobil uygulamasında quiz ve çalışma seanslarında kullanılan ses efektlerinin platformlar arası (Android, iOS, Web) çalışma prensipleri, karşılaşılan donanımsal sorunlar ve uygulanan **Audio Player Pool (Round-Robin)** mimarisi detaylandırılmıştır.

---

## 1. Cross-Platform Ses Yönetimi Neden Zordur?

Flutter UI tarafında tek bir Dart kodu ile tüm platformlarda pikselleri birebir aynı şekilde çizer (Canvas/Impeller). Ancak **Ses, Bluetooth veya Kamera** gibi donanım seviyesine inen konularda işletim sistemlerinin yerel ses motorları tamamen farklı kurallara sahiptir.

```
+-------------------------------------------------------------+
|               Flutter / Dart Kodu (Tek Kod)                 |
+-------------------------------------------------------------+
                              |
       (Platform Kanalları / Yerel Çağrılar)
         /                    |                    \
        v                     v                     v
 [Android: Java/Kotlin]  [iOS: Swift/Obj-C]    [Web: JavaScript]
  - AudioManager          - AVAudioSession       - Web Audio API
  - MediaPlayer           - AVAudioPlayer        - HTML Audio
  - SoundPool
```

### İşletim Sistemi Farkları:
* **Android:** Sesi `MediaPlayer`, `SoundPool` ve `AudioTrack` API'leri üzerinden yönetir. Android'de "Audio Focus" (diğer uygulamaların sesini kısma/kesme) ve ses akış kanalları (*Media, Alarm, Notification, Sonification*) bulunur.
* **iOS:** Apple'ın katı **`AVAudioSession`** politikası geçerlidir. Telefonun fiziksel "Sessiz Butonu" (Silent Switch), sesin kulaklığa/hoparlöre yönlendirilmesi ve arka planda müzik çalarken ses karıştırma (`mixWithOthers`) Apple'a özgü kurallarla belirlenir.
* **Web (Tarayıcılar):** İşletim sistemi kurallarından bağımsız olarak doğrudan **Web Audio API** ve HTML5 `<audio>` etiketini kullanır.

---

## 2. Karşılaşılan Sorunlar ve Çözümleri

### A. Dinamik WAV Üretimi vs Statik MP3 Asset
* **Eski Yaklaşım:** Dart kodu içinde matematiksel sinüs dalgaları (`sin`, `exp`, RIFF header) ile RAM'de WAV baytları üretilip geçici diske (`tempDir`) yazılmaya çalışılıyordu.
* **Sorun:** Android'in düşük gecikmeli ses motoru (`SoundPool`), RAM'deki bayt dizilerini (`BytesSource`) doğrudan desteklemez ve dosya izinleri/I/O gecikmeleri nedeniyle sesler Android'de sessiz kalır.
* **İdeal Çözüm:** Ses dosyalarını `assets/sounds/` altında hafif (10-50 KB) statik `.mp3` dosyaları olarak projeye gömmek ve `AssetSource` ile çağırmak.

---

## 3. Seri Tıklamalarda Ses Kesilmesi ve Audio Pool Mimarisi

### Sorun: Tek Oynatıcı Tıkanıklığı (Single Player Bottleneck)
Klasik bir `AudioPlayer` tekil nesne olarak tanımlandığında:
1. Kullanıcı 1. butona basar $\rightarrow$ Oynatıcı sesi çalmaya başlar (süre: ~0.5 sn).
2. Kullanıcı 0.1 sn sonra çok hızlıca 2. butona basar $\rightarrow$ Oynatıcı henüz meşgul (`PLAYING`) durumda olduğu için sonraki istekler işletim sistemi tarafından **yok sayılır (drop edilir)**.

---

### Çözüm: Audio Player Pool (Ses Havuzu - Round-Robin)

Oyun motorlarında (Unity, Unreal) silah sesleri ve patlamalar için kullanılan **Audio Pool** deseni projeye entegre edilmiştir.

#### Banka Gişesi Benzetmesi:
* Tek gişe memuru yerine yan yana **4 bağımsız gişe memuru** (`_poolSize = 4`) konumlandırılır.
* Her tıklamada sıradaki oynatıcı seçilir:
  * **1. Tıklama:** 1. Oynatıcı çalar.
  * **2. Tıklama (0.1 sn sonra):** 2. Oynatıcı devreye girer (1. ses kesilmez, üst üste çalar).
  * **3. Tıklama:** 3. Oynatıcı çalar.
  * **4. Tıklama:** 4. Oynatıcı çalar.
  * **5. Tıklama:** Dairesel döngü (Round-Robin) ile tekrar 1. Oynatıcıya dönülür (bu sürede ilk ses zaten bitmiştir).

---

## 4. `SoundService` Kod Yapısı

Dosya Yolu: `lib/core/services/sound_service.dart`

```dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});

class SoundService {
  static const int _poolSize = 4;
  final List<AudioPlayer> _players;
  int _nextIndex = 0;
  final bool _enableAudio;

  SoundService({AudioPlayer? player, bool enableAudio = true})
      : _enableAudio = enableAudio,
        _players = enableAudio
            ? (player != null ? [player] : List.generate(_poolSize, (_) => AudioPlayer()))
            : const [] {
    _initAudioContext();
  }

  Future<void> _initAudioContext() async {
    if (!_enableAudio || _players.isEmpty) return;
    for (final p in _players) {
      try {
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.ambient, // Diğer müzikleri durdurmaz, sessiz moda uyar
              options: {
                AVAudioSessionOptions.mixWithOthers,
                AVAudioSessionOptions.defaultToSpeaker,
              },
            ),
            android: AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: false,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
          ),
        );
      } catch (_) {}
    }
  }

  /// Round-Robin havuzundan sıradaki müsait oynatıcıyı getirir
  AudioPlayer? _getNextPlayer() {
    if (!_enableAudio || _players.isEmpty) return null;
    final player = _players[_nextIndex];
    _nextIndex = (_nextIndex + 1) % _players.length;
    return player;
  }

  Future<void> playCorrectSound() async {
    try {
      HapticFeedback.lightImpact();
      final player = _getNextPlayer();
      if (player != null) {
        await player.stop();
        await player.play(AssetSource('sounds/correct.mp3'), volume: 1.0);
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playWrongSound() async {
    try {
      HapticFeedback.heavyImpact();
      final player = _getNextPlayer();
      if (player != null) {
        await player.stop();
        await player.play(AssetSource('sounds/wrong.mp3'), volume: 1.0);
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void dispose() {
    for (final p in _players) {
      p.dispose();
    }
  }
}
```

---

## 5. Özet ve Best Practice Tavsiyeleri

1. **Asset Kullanımı:** Ses efektlerini uygulama içine gömülü (`assets/sounds/`) MP3/WAV formatında tutun.
2. **Audio Context:** iOS için `ambient` ve `mixWithOthers`, Android için `sonification` ve `media` kanallarını yapılandırın.
3. **Pool Pattern:** Hızlı arayüz ve oyun etkileşimlerinde tekil `AudioPlayer` yerine dairesel havuz (`AudioPlayer Pool`) kullanarak ses kayıplarını ve gecikmeleri tamamen ortadan kaldırın.
