import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

/// Centralized Text-to-Speech service for natural English pronunciation.
/// Handles iOS/Android audio session configuration and safe playback.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);

  TtsService() {
    _initTts();
  }

  bool get isPlaying => _isPlaying;

  Future<void> _initTts() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(false);

      _tts.setStartHandler(() {
        _isPlaying = true;
        isPlayingNotifier.value = true;
      });

      _tts.setCompletionHandler(() {
        _isPlaying = false;
        isPlayingNotifier.value = false;
      });

      _tts.setCancelHandler(() {
        _isPlaying = false;
        isPlayingNotifier.value = false;
      });

      _tts.setErrorHandler((_) {
        _isPlaying = false;
        isPlayingNotifier.value = false;
      });
    } catch (_) {}
  }

  Future<void> speak(String text, {VoidCallback? onStateChanged}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    if (_isPlaying) {
      await stop();
      onStateChanged?.call();
      return;
    }

    try {
      HapticFeedback.lightImpact();
      _isPlaying = true;
      isPlayingNotifier.value = true;
      onStateChanged?.call();

      await _tts.stop();

      // Auto-reset fallback safety net in case platform callback stalls
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (_isPlaying) {
          _isPlaying = false;
          isPlayingNotifier.value = false;
          onStateChanged?.call();
        }
      });

      await _tts.speak(clean);
    } catch (_) {
      _isPlaying = false;
      isPlayingNotifier.value = false;
      onStateChanged?.call();
    }
  }

  Future<void> stop({VoidCallback? onStateChanged}) async {
    try {
      _isPlaying = false;
      isPlayingNotifier.value = false;
      onStateChanged?.call();
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _tts.stop();
    isPlayingNotifier.dispose();
  }
}
