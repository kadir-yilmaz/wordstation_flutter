import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});

class SoundService {
  final AudioPlayer? _player;
  Uint8List? _correctWav;
  Uint8List? _wrongWav;
  String? _correctFilePath;
  String? _wrongFilePath;

  SoundService({AudioPlayer? player, bool enableAudio = true})
      : _player = enableAudio ? (player ?? AudioPlayer()) : null {
    _initSounds();
  }

  Future<void> _initSounds() async {
    try {
      _correctWav = _generateChimeWav();
      _wrongWav = _generateBuzzerWav();

      // Configure iOS & Android AudioContext for instant, reliable sound effects
      if (_player != null) {
        if (!kIsWeb) {
          await _player.setPlayerMode(PlayerMode.lowLatency);
        }
        await _player.setAudioContext(
          AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: {
                AVAudioSessionOptions.mixWithOthers,
                AVAudioSessionOptions.defaultToSpeaker,
              },
            ),
            android: AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: false,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.none,
            ),
          ),
        );
      }

      // Save to named .wav files in sandboxed temporary directory
      Directory? tempDir;
      try {
        tempDir = await getTemporaryDirectory();
      } catch (_) {
        tempDir = Directory.systemTemp;
      }

      final cFile = File('${tempDir.path}/wordstation_correct.wav');
      await cFile.writeAsBytes(_correctWav!, flush: true);
      _correctFilePath = cFile.path;

      final wFile = File('${tempDir.path}/wordstation_wrong.wav');
      await wFile.writeAsBytes(_wrongWav!, flush: true);
      _wrongFilePath = wFile.path;
    } catch (_) {
      // Fallback handled during play
    }
  }

  Future<void> playCorrectSound() async {
    try {
      HapticFeedback.lightImpact();
      if (_player != null) {
        await _player.stop();
        if (_correctFilePath != null && File(_correctFilePath!).existsSync()) {
          await _player.play(DeviceFileSource(_correctFilePath!, mimeType: 'audio/wav'), volume: 1.0);
        } else if (_correctWav != null) {
          await _player.play(BytesSource(_correctWav!, mimeType: 'audio/wav'), volume: 1.0);
        }
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> playWrongSound() async {
    try {
      HapticFeedback.heavyImpact();
      if (_player != null) {
        await _player.stop();
        if (_wrongFilePath != null && File(_wrongFilePath!).existsSync()) {
          await _player.play(DeviceFileSource(_wrongFilePath!, mimeType: 'audio/wav'), volume: 1.0);
        } else if (_wrongWav != null) {
          await _player.play(BytesSource(_wrongWav!, mimeType: 'audio/wav'), volume: 1.0);
        }
      }
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void dispose() {
    _player?.dispose();
  }

  /// Synthesize a cheerful 2-tone chime (587 Hz -> 880 Hz, D5 to A5)
  Uint8List _generateChimeWav() {
    const sampleRate = 22050;
    const durationSeconds = 0.35;
    final totalSamples = (sampleRate * durationSeconds).toInt();
    final pcmData = Int16List(totalSamples);

    final half = totalSamples ~/ 2;
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final freq = i < half ? 587.33 : 880.0; // D5 -> A5
      final envelope = exp(-i / (totalSamples * 0.4)); // Smooth natural decay
      final sample = (sin(2 * pi * freq * t) * envelope * 24000).toInt();
      pcmData[i] = sample.clamp(-32768, 32767);
    }

    return _createWav(pcmData, sampleRate);
  }

  /// Synthesize a crisp, unmistakable 2-tone descending buzzer (E4 -> B3 / 330 Hz -> 247 Hz with rich harmonics)
  Uint8List _generateBuzzerWav() {
    const sampleRate = 22050;
    const durationSeconds = 0.38;
    final totalSamples = (sampleRate * durationSeconds).toInt();
    final pcmData = Int16List(totalSamples);

    final half = totalSamples ~/ 2;
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final isFirstHalf = i < half;
      final freq = isFirstHalf ? 329.63 : 246.94; // E4 -> B3 (Classic descending error interval)
      
      // Envelope per pulse (2 distinct pulses: "Bzz-Bzz" / "Uh-Oh")
      final pulseT = isFirstHalf ? (i / half) : ((i - half) / half);
      final envelope = exp(-pulseT * 3.2); // Crisp percussive decay

      // Harmonics for rich mobile speaker presence
      final wave = 0.65 * sin(2 * pi * freq * t) +
                   0.25 * sin(2 * pi * freq * 3 * t) +
                   0.10 * sin(2 * pi * freq * 5 * t);

      final sample = (wave * envelope * 28000).toInt();
      pcmData[i] = sample.clamp(-32768, 32767);
    }

    return _createWav(pcmData, sampleRate);
  }

  /// Package raw 16-bit mono PCM samples into a standard RIFF/WAV container
  Uint8List _createWav(Int16List pcmData, int sampleRate) {
    final byteData = ByteData(44 + pcmData.length * 2);

    // RIFF chunk descriptor
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, 36 + pcmData.length * 2, Endian.little);
    byteData.setUint8(8, 0x57);  // 'W'
    byteData.setUint8(9, 0x41);  // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // 'fmt ' sub-chunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
    byteData.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    byteData.setUint16(32, 2, Endian.little);  // BlockAlign (1 channel * 2 bytes)
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample

    // 'data' sub-chunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, pcmData.length * 2, Endian.little);

    for (int i = 0; i < pcmData.length; i++) {
      byteData.setInt16(44 + i * 2, pcmData[i], Endian.little);
    }

    return byteData.buffer.asUint8List();
  }
}
