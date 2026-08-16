import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/word_model.dart';

class SynonymBadgeItem {
  final WordModel word;
  final String matchedMeaning;
  final List<Color> gradient;

  const SynonymBadgeItem({
    required this.word,
    required this.matchedMeaning,
    required this.gradient,
  });
}

class StudyState {
  final List<WordModel> words;
  final int currentIndex;
  final bool isFlipped;
  final bool isRandom;
  final bool isPlayingTts;
  final List<SynonymBadgeItem> synonymBadges;

  const StudyState({
    required this.words,
    required this.currentIndex,
    this.isFlipped = false,
    this.isRandom = false,
    this.isPlayingTts = false,
    this.synonymBadges = const [],
  });

  factory StudyState.empty() => const StudyState(
        words: [],
        currentIndex: 0,
      );

  WordModel? get currentWord =>
      words.isNotEmpty && currentIndex >= 0 && currentIndex < words.length
          ? words[currentIndex]
          : null;

  int get totalCount => words.length;

  StudyState copyWith({
    List<WordModel>? words,
    int? currentIndex,
    bool? isFlipped,
    bool? isRandom,
    bool? isPlayingTts,
    List<SynonymBadgeItem>? synonymBadges,
  }) {
    return StudyState(
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isRandom: isRandom ?? this.isRandom,
      isPlayingTts: isPlayingTts ?? this.isPlayingTts,
      synonymBadges: synonymBadges ?? this.synonymBadges,
    );
  }
}

final studyControllerProvider =
    StateNotifierProvider.autoDispose<StudyController, StudyState>((ref) {
  final controller = StudyController();
  ref.onDispose(() {
    controller.disposeTts();
  });
  return controller;
});

class StudyController extends StateNotifier<StudyState> {
  final FlutterTts _tts = FlutterTts();
  final Random _random = Random();
  List<WordModel> _allWords = [];

  // Inverted index for O(1) instantaneous synonym lookup across 2,000+ words
  final Map<String, List<WordModel>> _meaningIndex = {};
  final Map<String, List<String>> _wordMeaningsCache = {};

  static const List<List<Color>> synonymGradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)], // Meaning 1: Purple
    [Color(0xFF0BA360), Color(0xFF3CBA92)], // Meaning 2: Teal / Green
    [Color(0xFF3880FF), Color(0xFF6CB2EB)], // Meaning 3: Blue
    [Color(0xFFEA5455), Color(0xFFFEB692)], // Meaning 4: Coral / Red
    [Color(0xFFD946EF), Color(0xFFEC4899)], // Meaning 5: Pink / Magenta
    [Color(0xFFF59E0B), Color(0xFFD97706)], // Meaning 6: Amber
  ];

  StudyController() : super(StudyState.empty()) {
    _initTts();
  }

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

      _tts.setCompletionHandler(() {
        if (mounted) state = state.copyWith(isPlayingTts: false);
      });
      _tts.setCancelHandler(() {
        if (mounted) state = state.copyWith(isPlayingTts: false);
      });
      _tts.setErrorHandler((_) {
        if (mounted) state = state.copyWith(isPlayingTts: false);
      });
    } catch (_) {}
  }

  void _buildIndex(List<WordModel> words) {
    _meaningIndex.clear();
    _wordMeaningsCache.clear();

    for (final w in words) {
      final meanings = w.tr
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();

      if (meanings.isEmpty && w.tr.trim().isNotEmpty) {
        meanings.add(w.tr.trim().toLowerCase());
      }

      final key = w.id?.toString() ?? '${w.en}_${w.tr}';
      _wordMeaningsCache[key] = meanings;

      for (final m in meanings) {
        _meaningIndex.putIfAbsent(m, () => []).add(w);
      }
    }
  }

  void initWithWords(List<WordModel> words, {int initialIndex = 0}) {
    _allWords = List<WordModel>.from(words);
    _buildIndex(words);

    final validIndex = words.isEmpty
        ? 0
        : initialIndex.clamp(0, words.length - 1);

    final badges = _findSynonymBadges(words, validIndex);

    state = StudyState(
      words: words,
      currentIndex: validIndex,
      isFlipped: false,
      synonymBadges: badges,
    );
  }

  void onSearchChanged(String query) {
    if (_allWords.isEmpty) return;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      final validIndex = state.currentIndex.clamp(0, _allWords.length - 1);
      state = state.copyWith(
        words: _allWords,
        currentIndex: validIndex,
        synonymBadges: _findSynonymBadges(_allWords, validIndex),
      );
      return;
    }

    final filtered = _allWords.where((w) {
      final en = w.en.toLowerCase().trim();
      final tr = w.tr.toLowerCase().trim();
      return en.startsWith(q) || tr.startsWith(q);
    }).toList();

    // Strict alphabetical sorting by prefix (e.g. b -> ba -> be -> bi...)
    filtered.sort((a, b) {
      final aEn = a.en.toLowerCase().trim();
      final bEn = b.en.toLowerCase().trim();
      final aStarts = aEn.startsWith(q);
      final bStarts = bEn.startsWith(q);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return aEn.compareTo(bEn);
    });

    state = state.copyWith(
      words: filtered,
      currentIndex: 0,
      synonymBadges: filtered.isNotEmpty ? _findSynonymBadges(filtered, 0) : [],
    );
  }

  /// Instantaneous O(1) synonym retrieval using inverted index
  List<SynonymBadgeItem> _findSynonymBadges(
      List<WordModel> words, int targetIndex) {
    if (words.isEmpty || targetIndex < 0 || targetIndex >= words.length) {
      return [];
    }

    final current = words[targetIndex];
    final currentEn = current.en.toLowerCase().trim();
    final currentKey = current.id?.toString() ?? '${current.en}_${current.tr}';
    final atomicMeanings = _wordMeaningsCache[currentKey] ?? [];

    final result = <SynonymBadgeItem>[];
    final seenWordKeys = <dynamic>{};

    for (int i = 0; i < atomicMeanings.length; i++) {
      final meaning = atomicMeanings[i];
      final gradient = synonymGradients[i % synonymGradients.length];

      final matchingWords = _meaningIndex[meaning];
      if (matchingWords != null) {
        for (final w in matchingWords) {
          if (w.en.toLowerCase().trim() == currentEn) continue;
          final key = w.id ?? '${w.en}_${w.tr}';
          if (!seenWordKeys.contains(key)) {
            seenWordKeys.add(key);
            result.add(
              SynonymBadgeItem(
                word: w,
                matchedMeaning: meaning,
                gradient: gradient,
              ),
            );
          }
        }
      }
    }

    return result;
  }

  void flip() {
    HapticFeedback.lightImpact();
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  void next() {
    if (state.words.isEmpty) return;
    if (state.isRandom) {
      if (state.isPlayingTts) _tts.stop();
      _goToRandom();
      return;
    }

    if (state.currentIndex >= state.words.length - 1) {
      return;
    }

    HapticFeedback.selectionClick();
    if (state.isPlayingTts) {
      _tts.stop();
    }

    final nextIndex = state.currentIndex + 1;
    final badges = _findSynonymBadges(state.words, nextIndex);
    state = state.copyWith(
      currentIndex: nextIndex,
      isFlipped: false,
      isPlayingTts: false,
      synonymBadges: badges,
    );
  }

  void prev() {
    if (state.words.isEmpty) return;
    if (state.isRandom) {
      if (state.isPlayingTts) _tts.stop();
      _goToRandom();
      return;
    }

    if (state.currentIndex <= 0) {
      return;
    }

    HapticFeedback.selectionClick();
    if (state.isPlayingTts) {
      _tts.stop();
    }

    final prevIndex = state.currentIndex - 1;
    final badges = _findSynonymBadges(state.words, prevIndex);
    state = state.copyWith(
      currentIndex: prevIndex,
      isFlipped: false,
      isPlayingTts: false,
      synonymBadges: badges,
    );
  }

  void _goToRandom() {
    if (state.words.length <= 1) return;
    if (state.isPlayingTts) {
      _tts.stop();
    }
    int randomIndex;
    do {
      randomIndex = _random.nextInt(state.words.length);
    } while (randomIndex == state.currentIndex && state.words.length > 1);

    final badges = _findSynonymBadges(state.words, randomIndex);
    state = state.copyWith(
      currentIndex: randomIndex,
      isFlipped: false,
      isPlayingTts: false,
      synonymBadges: badges,
    );
  }

  void toggleRandom() {
    HapticFeedback.mediumImpact();
    // Immediate responsive jump on every tap
    if (state.isRandom) {
      _goToRandom();
    } else {
      state = state.copyWith(isRandom: true);
      _goToRandom();
    }
  }

  void seekTo(int index) {
    if (state.words.isEmpty) return;
    if (state.isPlayingTts) {
      _tts.stop();
    }
    final clamped = index.clamp(0, state.words.length - 1);
    if (clamped == state.currentIndex) return;

    final badges = _findSynonymBadges(state.words, clamped);
    state = state.copyWith(
      currentIndex: clamped,
      isFlipped: false,
      isPlayingTts: false,
      synonymBadges: badges,
    );
  }

  Future<void> speakCurrent() async {
    final current = state.currentWord;
    if (current == null || current.en.isEmpty) return;

    if (state.isPlayingTts) {
      await _tts.stop();
      if (mounted) state = state.copyWith(isPlayingTts: false);
      return;
    }

    try {
      HapticFeedback.lightImpact();
      if (mounted) state = state.copyWith(isPlayingTts: true);
      await _tts.stop();

      // Auto-reset timer safety net (max 1.4 seconds for a single word)
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted && state.isPlayingTts) {
          state = state.copyWith(isPlayingTts: false);
        }
      });

      await _tts.speak(current.en);
    } catch (_) {
      if (mounted) state = state.copyWith(isPlayingTts: false);
    }
  }

  Future<void> speakText(String text) async {
    if (text.isEmpty) return;
    try {
      HapticFeedback.lightImpact();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  void disposeTts() {
    _tts.stop();
  }
}
