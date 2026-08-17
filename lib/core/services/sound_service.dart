import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});

/// High-performance SoundService utilizing an Audio Player Pool (Round-Robin)
/// to allow rapid successive taps without audio cutting off or dropping.
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
              category: AVAudioSessionCategory.ambient,
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
      } catch (_) {
        // Ignore audio context configuration issues on unsupported targets
      }
    }
  }

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
