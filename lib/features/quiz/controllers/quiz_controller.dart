import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/sound_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../words/models/word_model.dart';
import '../models/quiz_history_model.dart';
import '../models/quiz_question.dart';
import '../repositories/quiz_repository.dart';

// ─── Quiz State ─────────────────────────────────────────────────────────────

class QuizState {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isQuizCompleted;
  final bool isEnglishToTurkish;
  final bool isDailyQuiz;
  final String quizTitle;
  final List<QuizQuestionResult> results;
  final List<QuizHistoryModel> historyList;
  final String? errorMessage;

  const QuizState({
    required this.questions,
    this.currentIndex = 0,
    this.score = 0,
    this.selectedAnswer,
    this.isAnswered = false,
    this.isQuizCompleted = false,
    this.isEnglishToTurkish = true,
    this.isDailyQuiz = false,
    this.quizTitle = 'Genel Test',
    this.results = const [],
    this.historyList = const [],
    this.errorMessage,
  });

  factory QuizState.initial() => const QuizState(questions: []);

  QuizQuestion? get currentQuestion =>
      questions.isNotEmpty && currentIndex >= 0 && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  int get totalQuestions => questions.length;
  int get correctCount => results.where((r) => r.isCorrect).length;
  int get wrongCount => results.where((r) => !r.isCorrect).length;
  int get maxScore => totalQuestions * 10;
  int get percentage =>
      maxScore > 0 ? ((score / maxScore) * 100).round() : 0;

  QuizState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? score,
    String? selectedAnswer,
    bool? isAnswered,
    bool? isQuizCompleted,
    bool? isEnglishToTurkish,
    bool? isDailyQuiz,
    String? quizTitle,
    List<QuizQuestionResult>? results,
    List<QuizHistoryModel>? historyList,
    String? errorMessage,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      selectedAnswer: selectedAnswer,
      isAnswered: isAnswered ?? this.isAnswered,
      isQuizCompleted: isQuizCompleted ?? this.isQuizCompleted,
      isEnglishToTurkish: isEnglishToTurkish ?? this.isEnglishToTurkish,
      isDailyQuiz: isDailyQuiz ?? this.isDailyQuiz,
      quizTitle: quizTitle ?? this.quizTitle,
      results: results ?? this.results,
      historyList: historyList ?? this.historyList,
      errorMessage: errorMessage,
    );
  }
}

// ─── Quiz Controller ────────────────────────────────────────────────────────

final quizControllerProvider =
    StateNotifierProvider<QuizController, QuizState>((ref) {
  final soundService = ref.watch(soundServiceProvider);
  final quizRepository = ref.watch(quizRepositoryProvider);
  final initialWords = ref.read(wordListControllerProvider).words;

  final controller = QuizController(
    initialWords,
    soundService: soundService,
    quizRepository: quizRepository,
  );

  // Update words pool gracefully
  ref.listen<WordListState>(wordListControllerProvider, (prev, next) {
    controller.updateWordsPool(next.words);
  });

  // Listen to Auth State changes
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    if (next.isAuthenticated) {
      controller.loadHistory();
    } else if (next.status == AuthStatus.unauthenticated) {
      controller.resetToSetup();
    }
  });

  return controller;
});

class QuizController extends StateNotifier<QuizState> {
  List<WordModel> _allWords;
  final SoundService _soundService;
  final IQuizRepository _quizRepository;
  final Random _random = Random();

  QuizController(
    this._allWords, {
    SoundService? soundService,
    required IQuizRepository quizRepository,
  })  : _soundService = soundService ?? SoundService(),
        // ignore: prefer_initializing_formals
        _quizRepository = quizRepository,
        super(QuizState.initial()) {
    loadHistory();
  }

  void updateWordsPool(List<WordModel> words) {
    _allWords = List<WordModel>.from(words);
  }

  /// Genel quiz geçmişini yükler.
  Future<void> loadHistory() async {
    try {
      final allHistory = await _quizRepository.getHistory();
      final generalHistory = allHistory.where((h) => !h.isDailyQuiz).toList();
      if (!mounted) return;
      state = state.copyWith(historyList: generalHistory);
    } catch (e) {
      dev.log('QuizController.loadHistory error: $e');
    }
  }

  /// Günlük quiz'i başlatır (PlanController'dan kelimeler gelir).
  void startDailyQuiz({
    required List<WordModel> words,
    required bool englishToTurkish,
    required String title,
  }) {
    if (words.isEmpty) return;

    final questions = _buildQuestionsFromWords(
      selectedWords: words,
      pool: _allWords,
      englishToTurkish: englishToTurkish,
    );

    state = QuizState(
      questions: questions,
      currentIndex: 0,
      score: 0,
      isAnswered: false,
      isQuizCompleted: false,
      isEnglishToTurkish: englishToTurkish,
      isDailyQuiz: true,
      quizTitle: title,
      results: [],
      historyList: state.historyList,
    );
  }

  void generateQuiz({
    List<WordModel>? customWords,
    int questionCount = 10,
    bool englishToTurkish = true,
    String title = 'Genel Test',
    bool isDailyQuiz = false,
  }) {
    final pool = (customWords != null && customWords.isNotEmpty)
        ? customWords
        : _allWords;

    if (pool.length < 4) {
      state = state.copyWith(questions: []);
      return;
    }

    final shuffled = List<WordModel>.from(pool)..shuffle(_random);
    final count = min(questionCount, shuffled.length);
    final selectedWords = shuffled.take(count).toList();

    final questions = _buildQuestionsFromWords(
      selectedWords: selectedWords,
      pool: pool,
      englishToTurkish: englishToTurkish,
    );

    state = QuizState(
      questions: questions,
      currentIndex: 0,
      score: 0,
      isAnswered: false,
      isQuizCompleted: false,
      isEnglishToTurkish: englishToTurkish,
      isDailyQuiz: isDailyQuiz,
      quizTitle: title,
      results: [],
      historyList: state.historyList,
    );
  }

  List<QuizQuestion> _buildQuestionsFromWords({
    required List<WordModel> selectedWords,
    required List<WordModel> pool,
    required bool englishToTurkish,
  }) {
    final questions = <QuizQuestion>[];

    for (final word in selectedWords) {
      final correctAnswer = englishToTurkish ? word.tr : word.en;
      final questionText = englishToTurkish ? word.en : word.tr;

      final otherWords = pool.where((w) => w.id != word.id).toList()
        ..shuffle(_random);
      final wrongOptions = <String>{};

      for (final other in otherWords) {
        final option = englishToTurkish ? other.tr : other.en;
        if (option.isNotEmpty && option != correctAnswer) {
          wrongOptions.add(option);
        }
        if (wrongOptions.length >= 3) break;
      }

      while (wrongOptions.length < 3) {
        wrongOptions.add('Seçenek ${wrongOptions.length + 1}');
      }

      final allOptions = [correctAnswer, ...wrongOptions]..shuffle(_random);

      questions.add(
        QuizQuestion(
          word: word,
          questionText: questionText,
          correctAnswer: correctAnswer,
          options: allOptions,
          isEnglishToTurkish: englishToTurkish,
        ),
      );
    }

    return questions;
  }

  Future<void> selectAnswer(String answer,
      {Duration delay = const Duration(milliseconds: 450)}) async {
    if (state.isAnswered || state.currentQuestion == null) return;

    final currentQ = state.currentQuestion!;
    final isCorrect = answer == currentQ.correctAnswer;
    final newScore = isCorrect ? state.score + 10 : state.score;

    if (isCorrect) {
      _soundService.playCorrectSound();
    } else {
      _soundService.playWrongSound();
    }

    final newResult = QuizQuestionResult(
      word: currentQ.word,
      questionText: currentQ.questionText,
      correctAnswer: currentQ.correctAnswer,
      selectedAnswer: answer,
      isCorrect: isCorrect,
    );

    state = state.copyWith(
      selectedAnswer: answer,
      isAnswered: true,
      score: newScore,
      results: [...state.results, newResult],
    );

    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    await nextQuestion();
  }

  Future<void> nextQuestion() async {
    if (state.currentIndex + 1 < state.totalQuestions) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        selectedAnswer: null,
        isAnswered: false,
      );
    } else {
      state = state.copyWith(isQuizCompleted: true);
      if (!state.isDailyQuiz) {
        await _saveGeneralQuizHistory();
      }
      // Günlük quiz tamamlanınca plan'ın güncellenmesi DailyPlanPage'den yapılacak.
    }
  }

  Future<void> _saveGeneralQuizHistory() async {
    final historyEntry = QuizHistoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      title: state.quizTitle,
      score: state.score,
      maxScore: state.maxScore,
      totalQuestions: state.totalQuestions,
      correctCount: state.correctCount,
      wrongCount: state.wrongCount,
      isDailyQuiz: false,
      results: state.results,
    );

    try {
      await _quizRepository.saveHistory(historyEntry);
    } catch (e) {
      dev.log('QuizController._saveGeneralQuizHistory error: $e');
    }

    // Güncel geçmişi cloud'dan çek
    List<QuizHistoryModel> updatedHistory = [
      historyEntry,
      ...state.historyList,
    ];
    try {
      final cloudHistory = await _quizRepository.getHistory();
      if (cloudHistory.isNotEmpty) {
        updatedHistory = cloudHistory.where((h) => !h.isDailyQuiz).toList();
      }
    } catch (_) {}

    if (!mounted) return;
    state = state.copyWith(historyList: updatedHistory);
  }

  void restartQuiz() {
    if (state.questions.isNotEmpty) {
      generateQuiz(
        customWords: state.questions.map((q) => q.word).toList(),
        questionCount: state.questions.length,
        englishToTurkish: state.isEnglishToTurkish,
        title: state.quizTitle,
        isDailyQuiz: state.isDailyQuiz,
      );
    }
  }

  void resetToSetup() {
    state = state.copyWith(
      questions: [],
      currentIndex: 0,
      score: 0,
      selectedAnswer: null,
      isAnswered: false,
      isQuizCompleted: false,
      results: [],
    );
    loadHistory();
  }

  Future<void> clearAllHistory() async {
    try {
      await _quizRepository.clearHistory();
    } catch (e) {
      dev.log('QuizController.clearAllHistory error: $e');
    }
    state = state.copyWith(historyList: []);
  }

  Future<void> loadInitialData() => loadHistory();

  Future<void> clearHistory({bool isDailyQuiz = false}) async {
    try {
      await _quizRepository.clearHistory(isDailyQuiz: isDailyQuiz);
    } catch (e) {
      dev.log('QuizController.clearHistory error: $e');
    }
    state = state.copyWith(historyList: []);
  }

  Future<void> clearGeneralHistory() async {
    try {
      await _quizRepository.clearHistory(isDailyQuiz: false);
    } catch (e) {
      dev.log('QuizController.clearGeneralHistory error: $e');
    }
    state = state.copyWith(historyList: []);
  }
}
