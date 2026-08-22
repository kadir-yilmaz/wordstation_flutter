import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/tts_service.dart';
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
  final tts = ref.watch(ttsServiceProvider);
  return StudyController(tts);
});

class StudyController extends StateNotifier<StudyState> {
  final TtsService _tts;
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

  StudyController(this._tts) : super(StudyState.empty());

  void _buildIndex(List<WordModel> words) {
    _meaningIndex.clear();
    _wordMeaningsCache.clear();

    for (final w in words) {
      final rawMeanings = w.tr
          .split(RegExp(r'[,;/]'))
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();

      final meanings = <String>{};
      for (final m in rawMeanings) {
        final cleaned = m.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
        if (cleaned.isNotEmpty) {
          meanings.add(cleaned);
        }
        meanings.add(m);
      }

      if (meanings.isEmpty && w.tr.trim().isNotEmpty) {
        meanings.add(w.tr.trim().toLowerCase());
      }

      final key = w.id?.toString() ?? '${w.en}_${w.tr}';
      _wordMeaningsCache[key] = meanings.toList();

      for (final m in meanings) {
        _meaningIndex.putIfAbsent(m, () => []).add(w);
      }
    }
  }

  void initWithWords(
    List<WordModel> words, {
    int initialIndex = 0,
    List<WordModel>? allVocabularyWords,
  }) {
    _allWords = List<WordModel>.from(words);
    final vocab = allVocabularyWords != null && allVocabularyWords.isNotEmpty
        ? allVocabularyWords
        : words;
    _buildIndex(vocab);

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
      return en.startsWith(q);
    }).toList();

    // Strict alphabetical sorting by English word
    filtered.sort((a, b) {
      final aEn = a.en.toLowerCase().trim();
      final bEn = b.en.toLowerCase().trim();
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
    _goToRandom();
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

  /// Kelimeyi sil — index'i ve arama durumunu koru
  void removeWord(dynamic wordId) {
    // 1. Master listeden çıkar
    _allWords.removeWhere((w) => w.id == wordId);

    // 2. Şu anki (filtrelenmiş olabilir) listeden çıkar
    final currentWords = List<WordModel>.from(state.words);
    currentWords.removeWhere((w) => w.id == wordId);

    if (currentWords.isEmpty) {
      state = StudyState.empty();
      return;
    }

    // 3. Index'i koru — silinen eleman sonuncuysa bir geri git
    final newIndex = state.currentIndex >= currentWords.length
        ? currentWords.length - 1
        : state.currentIndex;

    // 4. Synonym index'ini yeniden oluştur ve güncelle
    _buildIndex(_allWords);
    final badges = _findSynonymBadges(currentWords, newIndex);

    state = state.copyWith(
      words: currentWords,
      currentIndex: newIndex,
      isFlipped: false,
      synonymBadges: badges,
    );
  }

  /// Kelimeyi yerinde güncelle — index'i ve arama durumunu koru
  void updateWordInPlace(WordModel updated) {
    // 1. Master listede güncelle
    for (int i = 0; i < _allWords.length; i++) {
      if (_allWords[i].id == updated.id) {
        _allWords[i] = updated;
        break;
      }
    }

    // 2. Şu anki (filtrelenmiş) listede güncelle
    final currentWords = state.words.map((w) {
      if (w.id == updated.id) return updated;
      return w;
    }).toList();

    // 3. Synonym index'ini yeniden oluştur
    _buildIndex(_allWords);
    final badges = _findSynonymBadges(currentWords, state.currentIndex);

    state = state.copyWith(
      words: currentWords,
      synonymBadges: badges,
    );
  }

  /// Yeni kelime ekle — mevcut index'i ve arama durumunu koru
  void addNewWord(WordModel word) {
    // 1. Master listeye ekle
    _allWords.add(word);

    // 2. Synonym index'ini yeniden oluştur
    _buildIndex(_allWords);
    final badges = _findSynonymBadges(state.words, state.currentIndex);

    state = state.copyWith(
      synonymBadges: badges,
    );
  }

  Future<void> speakCurrent() async {
    final current = state.currentWord;
    if (current == null || current.en.isEmpty) return;

    await _tts.speak(
      current.en,
      onStateChanged: () {
        if (mounted) {
          state = state.copyWith(isPlayingTts: _tts.isPlaying);
        }
      },
    );
  }

  Future<void> speakText(String text) async {
    if (text.isEmpty) return;
    await _tts.speak(text);
  }
}
