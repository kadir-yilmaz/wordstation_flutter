import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../words/models/word_model.dart';
import '../models/daily_plan_day_model.dart';
import '../models/daily_quiz_plan_model.dart';
import '../models/quiz_history_model.dart';
import '../models/quiz_question.dart';
import '../repositories/quiz_repository.dart';
import '../services/daily_quiz_api_service.dart';
import '../services/quiz_history_api_service.dart';

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
  final List<DailyPlanDayModel> dailyPlanDays;
  final DailyQuizPlanModel? dailyPlan;
  final bool isDailyQuizCompletedToday;
  final bool hasPlanLoadError;
  final bool isPlanLoaded;
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
    this.dailyPlanDays = const [],
    this.dailyPlan,
    this.isDailyQuizCompletedToday = false,
    this.hasPlanLoadError = false,
    this.isPlanLoaded = false,
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
    List<DailyPlanDayModel>? dailyPlanDays,
    DailyQuizPlanModel? dailyPlan,
    bool clearDailyPlan = false,
    bool? isDailyQuizCompletedToday,
    bool? hasPlanLoadError,
    bool? isPlanLoaded,
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
      dailyPlanDays: clearDailyPlan ? const [] : (dailyPlanDays ?? this.dailyPlanDays),
      dailyPlan: clearDailyPlan ? null : (dailyPlan ?? this.dailyPlan),
      isDailyQuizCompletedToday:
          isDailyQuizCompletedToday ?? this.isDailyQuizCompletedToday,
      hasPlanLoadError: hasPlanLoadError ?? this.hasPlanLoadError,
      isPlanLoaded: isPlanLoaded ?? this.isPlanLoaded,
      errorMessage: errorMessage,
    );
  }
}

final quizControllerProvider =
    StateNotifierProvider<QuizController, QuizState>((ref) {
  final soundService = ref.watch(soundServiceProvider);
  final apiService = ref.watch(dailyQuizApiServiceProvider);
  final historyApiService = ref.watch(quizHistoryApiServiceProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  final quizRepository = ref.watch(quizRepositoryProvider);
  final initialWords = ref.read(wordListControllerProvider).words;

  final controller = QuizController(
    initialWords,
    soundService: soundService,
    apiService: apiService,
    historyApiService: historyApiService,
    storageService: storageService,
    quizRepository: quizRepository,
  );

  // Update words pool gracefully without destroying the QuizController and its history state
  ref.listen<WordListState>(wordListControllerProvider, (prev, next) {
    controller.updateWordsPool(next.words);
  });

  // Listen to Auth State changes (when user logs in or out, reload data)
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    if (next.isAuthenticated) {
      controller.loadInitialData();
    } else if (next.status == AuthStatus.unauthenticated) {
      controller.resetToSetup();
    }
  });

  return controller;
});

class QuizController extends StateNotifier<QuizState> {
  List<WordModel> _allWords;
  final SoundService _soundService;
  final DailyQuizApiService? apiService;
  final QuizHistoryApiService? historyApiService;
  final IQuizRepository? quizRepository;
  final Random _random = Random();

  QuizController(
    this._allWords, {
    SoundService? soundService,
    this.apiService,
    this.historyApiService,
    SecureStorageService? storageService,
    this.quizRepository,
  })  : _soundService = soundService ?? SoundService(),
        super(QuizState.initial()) {
    _initFromCacheAndFetchCloud();
  }

  void updateWordsPool(List<WordModel> words) {
    _allWords = List<WordModel>.from(words);
  }

  /// 1. Anında yerel önbellekten (Cache) yükle (0ms bekleme / flicker engelleme)
  /// 2. Arka planda Cloud API ile senkronize et (SWR - Stale While Revalidate)
  Future<void> _initFromCacheAndFetchCloud() async {
    await loadInitialData();
  }

  /// Tüm veriler Repository veya API üzerinden çekilir (Offline-First)
  Future<void> loadInitialData() async {
    final todayStr = _formatTodayDate();

    // 1. Genel test geçmişi
    List<QuizHistoryModel> history = [];
    if (quizRepository != null) {
      try {
        final allHistory = await quizRepository!.getHistory();
        history = allHistory.where((h) => !h.isDailyQuiz).toList();
      } catch (e) {
        dev.log('QuizController.loadInitialData history error: $e');
      }
    } else if (historyApiService != null) {
      try {
        final allHistory = await historyApiService!.getHistory();
        history = allHistory.where((h) => !h.isDailyQuiz).toList();
      } catch (e) {
        dev.log('QuizController.loadInitialData history API error: $e');
      }
    }

    // 2. Günlük Quiz planı ve tamamlanan günler
    DailyQuizPlanModel? cloudPlan;
    List<DailyPlanDayModel> planDays = [];
    bool isDailyDone = false;
    bool hasPlanError = false;
    String? errorMsg;

    if (quizRepository != null) {
      try {
        cloudPlan = await quizRepository!.getActivePlan();
        if (cloudPlan != null) {
          isDailyDone = cloudPlan.isCompletedToday(todayStr);
          final planIntId = int.tryParse(cloudPlan.id) ?? 0;
          planDays = await quizRepository!.getPlanDays(planIntId);
        }
      } catch (e) {
        hasPlanError = true;
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
    } else if (apiService != null) {
      try {
        cloudPlan = await apiService!.getPlan();
        if (cloudPlan != null) {
          isDailyDone = cloudPlan.isCompletedToday(todayStr);
          planDays = await apiService!.getDayHistories();
        }
      } catch (e) {
        hasPlanError = true;
        errorMsg = e.toString().replaceAll('Exception: ', '');
        dev.log('QuizController.loadInitialData plan API error: $e');
      }
    }

    if (!mounted) return;
    final effectivePlan = (quizRepository != null || apiService != null)
        ? (cloudPlan ?? (hasPlanError ? state.dailyPlan : null))
        : state.dailyPlan;

    state = state.copyWith(
      historyList: history,
      dailyPlan: effectivePlan,
      dailyPlanDays: effectivePlan != null ? planDays : const [],
      clearDailyPlan: (quizRepository != null || apiService != null) && cloudPlan == null && !hasPlanError,
      isDailyQuizCompletedToday: cloudPlan != null ? isDailyDone : state.isDailyQuizCompletedToday,
      hasPlanLoadError: hasPlanError,
      isPlanLoaded: true,
      errorMessage: errorMsg,
    );
  }

  /// Yeni bir plan oluşturur (Sequential)
  Future<bool> createPlan({
    required String listName,
    required int dailyCount,
    required bool englishToTurkish,
  }) async {
    final matchingWords = (listName == 'Tümü' || listName == 'All')
        ? List<WordModel>.from(_allWords)
        : _allWords.where((w) => w.listName == listName).toList();

    if (matchingWords.isEmpty) {
      state = state.copyWith(errorMessage: 'Seçilen listede kelime bulunamadı.');
      return false;
    }

    if (apiService != null) {
      try {
        final newPlan = await apiService!.createOrResetPlan(
          listName: listName,
          dailyCount: dailyCount,
          isEnglishToTurkish: englishToTurkish,
        );

        if (newPlan != null) {
          state = state.copyWith(
            dailyPlan: newPlan,
            dailyPlanDays: const [],
            isDailyQuizCompletedToday: false,
            hasPlanLoadError: false,
            errorMessage: null,
          );
          return true;
        }
      } catch (e) {
        dev.log('QuizController.createPlan error: $e');
        state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
        return false;
      }
    }

    // Fallback for standalone mock testing
    final shuffled = List<WordModel>.from(matchingWords)..shuffle(_random);
    final shuffledIds = shuffled.map((w) => w.id).toList();

    final fallbackPlan = DailyQuizPlanModel(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}',
      listName: listName,
      dailyCount: dailyCount,
      shuffledWordIds: shuffledIds,
      currentPointer: 0,
      lastCompletedDate: null,
      streakDays: 0,
      isEnglishToTurkish: englishToTurkish,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      dailyPlan: fallbackPlan,
      dailyPlanDays: const [],
      isDailyQuizCompletedToday: false,
      hasPlanLoadError: false,
      errorMessage: null,
    );
    return true;
  }

  Future<bool> deleteDailyPlan() async {
    state = state.copyWith(errorMessage: null);

    if (apiService != null) {
      try {
        await apiService!.deletePlan();
      } catch (e) {
        dev.log('QuizController.deleteDailyPlan error: $e');
        state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
        return false;
      }
    }

    state = state.copyWith(
      clearDailyPlan: true,
      dailyPlanDays: const [],
      isDailyQuizCompletedToday: false,
      hasPlanLoadError: false,
    );
    return true;
  }

  void startDailyQuizForToday() {
    final plan = state.dailyPlan;
    if (plan == null || plan.isPlanFinished) return;

    final start = plan.currentPointer;
    final end = min(start + plan.dailyCount, plan.totalWords);
    if (start >= end) return;
    final batchIds = plan.shuffledWordIds.sublist(start, end);

    final selectedWords = <WordModel>[];
    for (final id in batchIds) {
      for (final w in _allWords) {
        if (w.id == id) {
          selectedWords.add(w);
          break;
        }
      }
    }

    if (selectedWords.isEmpty) return;

    final questions = _buildQuestionsFromWords(
      selectedWords: selectedWords,
      pool: _allWords,
      englishToTurkish: plan.isEnglishToTurkish,
    );

    final title = 'Günün Quizi (Gün ${plan.currentDay}/${plan.totalDays})';

    state = QuizState(
      questions: questions,
      currentIndex: 0,
      score: 0,
      isAnswered: false,
      isQuizCompleted: false,
      isEnglishToTurkish: plan.isEnglishToTurkish,
      isDailyQuiz: true,
      quizTitle: title,
      results: [],
      historyList: state.historyList,
      dailyPlan: state.dailyPlan,
      isDailyQuizCompletedToday: false,
    );
  }

  void generateDailyQuiz({
    int questionCount = 10,
    bool englishToTurkish = true,
  }) {
    generateQuiz(
      questionCount: questionCount,
      englishToTurkish: englishToTurkish,
      title: 'Günün Quizi',
      isDailyQuiz: true,
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
      dailyPlan: state.dailyPlan,
      isDailyQuizCompletedToday: state.isDailyQuizCompletedToday,
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

      // Pick 3 distinct wrong options
      final otherWords = pool.where((w) => w.id != word.id).toList()..shuffle(_random);
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

  Future<void> selectAnswer(String answer, {Duration delay = const Duration(milliseconds: 450)}) async {
    if (state.isAnswered || state.currentQuestion == null) return;

    final currentQ = state.currentQuestion!;
    final isCorrect = answer == currentQ.correctAnswer;
    final newScore = isCorrect ? state.score + 10 : state.score;

    // Audio Feedback
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

    // Auto-advance to next question smoothly
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
      // Quiz Finished -> Save to History
      state = state.copyWith(isQuizCompleted: true);
      await _saveCompletedQuiz();
    }
  }

  Future<void> _saveCompletedQuiz() async {
    if (state.isDailyQuiz && state.dailyPlan != null) {
      final plan = state.dailyPlan!;
      final todayStr = _formatTodayDate();
      final newStreak = plan.streakDays + 1;
      final newPointer = min(plan.currentPointer + state.totalQuestions, plan.totalWords);
      final dayNumber = plan.currentDay;

      // 1. Günlük test sonucunu doğrudan DailyPlanDayHistories tablosuna kaydet
      if (apiService != null) {
        try {
          final resultsJson = jsonEncode(state.results.map((r) => r.toJson()).toList());
          await apiService!.saveDayHistory(
            dayNumber: dayNumber,
            totalQuestions: state.totalQuestions,
            correctCount: state.correctCount,
            wrongCount: state.wrongCount,
            score: state.score,
            maxScore: state.maxScore,
            resultsJson: resultsJson,
          );
        } catch (e) {
          dev.log('QuizController._saveCompletedQuiz saveDayHistory error: $e');
        }
      }

      // 2. Günlük Quiz plan ilerlemesini DB'de güncelle
      DailyQuizPlanModel? updatedPlan;
      if (apiService != null) {
        try {
          updatedPlan = await apiService!.updateProgress(
            newPointer: newPointer,
            lastCompletedDate: todayStr,
            streakDays: newStreak,
          );
        } catch (e) {
          dev.log('QuizController._saveCompletedQuiz plan progress API error: $e');
        }
      }

      updatedPlan ??= plan.copyWith(
        currentPointer: newPointer,
        lastCompletedDate: todayStr,
        streakDays: newStreak,
      );

      // 3. Güncel geçmiş günleri hazırla ve DB'den çek
      final currentDayModel = DailyPlanDayModel(
        id: DateTime.now().millisecondsSinceEpoch,
        dailyQuizPlanId: int.tryParse(plan.id) ?? 0,
        dayNumber: dayNumber,
        completedAt: DateTime.now(),
        totalQuestions: state.totalQuestions,
        correctCount: state.correctCount,
        wrongCount: state.wrongCount,
        score: state.score,
        maxScore: state.maxScore,
        results: state.results,
      );

      List<DailyPlanDayModel> updatedDays = [
        currentDayModel,
        ...state.dailyPlanDays.where((d) => d.dayNumber != dayNumber)
      ];

      if (apiService != null) {
        try {
          final cloudDays = await apiService!.getDayHistories();
          if (cloudDays.isNotEmpty) {
            updatedDays = cloudDays;
          }
        } catch (_) {}
      }

      if (!mounted) return;
      state = state.copyWith(
        dailyPlan: updatedPlan,
        dailyPlanDays: updatedDays,
        isDailyQuizCompletedToday: true,
      );
      return;
    }

    // GENEL TEST: Doğrudan QuizHistories tablosuna kaydedilir
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

    if (historyApiService != null) {
      try {
        await historyApiService!.saveHistory(historyEntry);
      } catch (e) {
        dev.log('QuizController._saveCompletedQuiz history API error: $e');
      }
    }

    List<QuizHistoryModel> updatedHistory = [historyEntry, ...state.historyList];
    if (historyApiService != null) {
      try {
        final cloudHistory = await historyApiService!.getHistory();
        if (cloudHistory.isNotEmpty) {
          updatedHistory = cloudHistory.where((h) => !h.isDailyQuiz).toList();
        }
      } catch (_) {}
    }

    if (!mounted) return;
    state = state.copyWith(
      historyList: updatedHistory,
    );
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
    loadInitialData();
  }

  Future<void> clearAllHistory() async {
    if (historyApiService != null) {
      try {
        await historyApiService!.clearHistory();
      } catch (e) {
        dev.log('QuizController.clearAllHistory error: $e');
      }
    }
    state = state.copyWith(historyList: []);
  }

  Future<void> clearGeneralHistory() async {
    if (historyApiService != null) {
      try {
        await historyApiService!.clearHistory(isDailyQuiz: false);
      } catch (e) {
        dev.log('QuizController.clearGeneralHistory error: $e');
      }
    }
    state = state.copyWith(historyList: []);
  }

  Future<void> clearDailyHistory() async {
    state = state.copyWith(dailyPlanDays: []);
  }

  Future<void> clearHistory({bool isDailyQuiz = false}) async {
    if (isDailyQuiz) {
      await clearDailyHistory();
    } else {
      await clearGeneralHistory();
    }
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
