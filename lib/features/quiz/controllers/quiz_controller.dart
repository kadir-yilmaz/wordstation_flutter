import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../words/models/word_model.dart';
import '../models/daily_quiz_plan_model.dart';
import '../models/quiz_history_model.dart';
import '../models/quiz_question.dart';
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
  final DailyQuizPlanModel? dailyPlan;
  final List<DailyQuizPlanModel> allPlans;
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
    this.dailyPlan,
    this.allPlans = const [],
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
    DailyQuizPlanModel? dailyPlan,
    List<DailyQuizPlanModel>? allPlans,
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
      dailyPlan: clearDailyPlan ? null : (dailyPlan ?? this.dailyPlan),
      allPlans: allPlans ?? this.allPlans,
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
  final initialWords = ref.read(wordListControllerProvider).words;

  final controller = QuizController(
    initialWords,
    soundService: soundService,
    apiService: apiService,
    historyApiService: historyApiService,
    storageService: storageService,
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
  final DailyQuizApiService? _apiService;
  final QuizHistoryApiService? _historyApiService;
  final SecureStorageService? _storageService;
  final Random _random = Random();

  QuizController(
    this._allWords, {
    SoundService? soundService,
    DailyQuizApiService? apiService,
    QuizHistoryApiService? historyApiService,
    SecureStorageService? storageService,
  })  : _soundService = soundService ?? SoundService(),
        // ignore: prefer_initializing_formals
        _apiService = apiService,
        // ignore: prefer_initializing_formals
        _historyApiService = historyApiService,
        // ignore: prefer_initializing_formals
        _storageService = storageService,
        super(QuizState.initial()) {
    _initFromCacheAndFetchCloud();
  }

  void updateWordsPool(List<WordModel> words) {
    _allWords = List<WordModel>.from(words);
  }

  /// 1. Anında yerel önbellekten (Cache) yükle (0ms bekleme / flicker engelleme)
  /// 2. Arka planda Cloud API ile senkronize et (SWR - Stale While Revalidate)
  Future<void> _initFromCacheAndFetchCloud() async {
    if (_storageService != null) {
      try {
        final cachedPlan = await _storageService.getCachedDailyPlan();
        if (cachedPlan != null && mounted) {
          final todayStr = _formatTodayDate();
          state = state.copyWith(
            dailyPlan: cachedPlan,
            isDailyQuizCompletedToday: cachedPlan.isCompletedToday(todayStr),
            isPlanLoaded: true,
          );
        }
      } catch (e) {
        dev.log('QuizController._initFromCacheAndFetchCloud cache error: $e');
      }
    }

    await loadInitialData();
  }

  /// Tüm veriler doğrudan API'den (Cloud) çekilir ve yerel önbellek güncellenir
  Future<void> loadInitialData() async {
    final todayStr = _formatTodayDate();

    // 1. Test geçmişini API'den çek
    List<QuizHistoryModel> history = [];
    if (_historyApiService != null) {
      try {
        history = await _historyApiService.getHistory();
      } catch (e) {
        dev.log('QuizController.loadInitialData history API error: $e');
      }
    }

    // 2. Günlük Quiz planlarını API'den çek
    List<DailyQuizPlanModel> allPlans = [];
    DailyQuizPlanModel? cloudPlan;
    bool isDailyDone = false;
    bool hasPlanError = false;
    String? errorMsg;

    if (_apiService != null) {
      try {
        allPlans = await _apiService.getAllPlans();
        if (allPlans.isNotEmpty) {
          cloudPlan = allPlans.firstWhere((p) => p.isActive, orElse: () => allPlans.first);
        } else {
          cloudPlan = await _apiService.getPlan();
          if (cloudPlan != null) {
            allPlans = [cloudPlan];
          }
        }

        if (cloudPlan != null) {
          isDailyDone = cloudPlan.isCompletedToday(todayStr);
          await _storageService?.saveCachedDailyPlan(cloudPlan);
        } else {
          // Cloud says no plan exists
          await _storageService?.clearCachedDailyPlan();
        }
      } catch (e) {
        hasPlanError = true;
        errorMsg = e.toString().replaceAll('Exception: ', '');
        dev.log('QuizController.loadInitialData plan API error: $e');
      }
    }

    if (!mounted) return;
    state = state.copyWith(
      historyList: history,
      allPlans: allPlans.isNotEmpty ? allPlans : state.allPlans,
      dailyPlan: _apiService != null
          ? (cloudPlan ?? (hasPlanError ? state.dailyPlan : null))
          : state.dailyPlan,
      clearDailyPlan: _apiService != null && cloudPlan == null && !hasPlanError,
      isDailyQuizCompletedToday: cloudPlan != null ? isDailyDone : state.isDailyQuizCompletedToday,
      hasPlanLoadError: hasPlanError,
      isPlanLoaded: true,
      errorMessage: errorMsg,
    );
  }

  /// Birden fazla plan arasında aktif planı değiştirir
  Future<bool> switchActivePlan(String planId) async {
    final target = state.allPlans.firstWhere(
      (p) => p.id == planId,
      orElse: () => state.dailyPlan ?? DailyQuizPlanModel(id: '', listName: '', dailyCount: 0, shuffledWordIds: const [], createdAt: DateTime.fromMillisecondsSinceEpoch(0)),
    );
    if (target.id.isEmpty) return false;

    if (_apiService != null) {
      try {
        await _apiService.setActivePlan(planId);
      } catch (e) {
        dev.log('QuizController.switchActivePlan error: $e');
      }
    }

    final todayStr = _formatTodayDate();
    final updatedAllPlans = state.allPlans.map((p) {
      return p.copyWith(isActive: p.id == planId);
    }).toList();

    await _storageService?.saveCachedDailyPlan(target);

    state = state.copyWith(
      dailyPlan: target,
      allPlans: updatedAllPlans,
      isDailyQuizCompletedToday: target.isCompletedToday(todayStr),
    );
    return true;
  }

  /// Yeni bir plan oluşturur (Otomatik Sıralı veya Açık Büfe)
  Future<bool> createPlan({
    String? title,
    required String listName,
    required int dailyCount,
    required bool englishToTurkish,
    PlanType planType = PlanType.sequential,
  }) async {
    final matchingWords = (listName == 'Tümü' || listName == 'All')
        ? List<WordModel>.from(_allWords)
        : _allWords.where((w) => w.listName == listName).toList();

    if (matchingWords.isEmpty) {
      state = state.copyWith(errorMessage: 'Seçilen listede kelime bulunamadı.');
      return false;
    }

    final shuffled = List<WordModel>.from(matchingWords)..shuffle(_random);
    final shuffledIds = shuffled.map((w) => w.id).toList();

    if (_apiService != null) {
      try {
        final newPlan = await _apiService.createPlan(
          title: title,
          listName: listName,
          dailyCount: dailyCount,
          isEnglishToTurkish: englishToTurkish,
          planType: planType,
          shuffledWordIds: shuffledIds,
          setAsActive: true,
        );

        if (newPlan != null) {
          final updatedList = [
            newPlan,
            ...state.allPlans.map((p) => p.copyWith(isActive: false))
          ];
          await _storageService?.saveCachedDailyPlan(newPlan);
          state = state.copyWith(
            dailyPlan: newPlan,
            allPlans: updatedList,
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
    final fallbackPlan = DailyQuizPlanModel(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}',
      title: title ?? '',
      listName: listName,
      planType: planType,
      dailyCount: dailyCount,
      shuffledWordIds: shuffledIds,
      completedWordIds: const [],
      dailySelectedWordIds: const [],
      currentPointer: 0,
      lastCompletedDate: null,
      streakDays: 0,
      isEnglishToTurkish: englishToTurkish,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final updatedAll = [
      fallbackPlan,
      ...state.allPlans.map((p) => p.copyWith(isActive: false))
    ];

    state = state.copyWith(
      dailyPlan: fallbackPlan,
      allPlans: updatedAll,
      isDailyQuizCompletedToday: false,
      hasPlanLoadError: false,
      errorMessage: null,
    );
    return true;
  }

  Future<bool> startOrResetDailyPlan({
    required String listName,
    required int dailyCount,
    required bool englishToTurkish,
  }) async {
    return createPlan(
      listName: listName,
      dailyCount: dailyCount,
      englishToTurkish: englishToTurkish,
      planType: PlanType.sequential,
    );
  }

  /// Açık Büfe modunda bugün için kelime seçimi yapar (Örn: 50 kelime)
  Future<bool> selectBuffetWords(List<dynamic> wordIds) async {
    final activePlan = state.dailyPlan;
    if (activePlan == null || !activePlan.isOpenBuffet) return false;

    if (_apiService != null) {
      try {
        final updated = await _apiService.selectBuffetWords(activePlan.id, wordIds);
        if (updated != null) {
          _updatePlanInState(updated);
          return true;
        }
      } catch (e) {
        dev.log('QuizController.selectBuffetWords error: $e');
        state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
        return false;
      }
    }

    final localUpdated = activePlan.copyWith(dailySelectedWordIds: wordIds);
    _updatePlanInState(localUpdated);
    return true;
  }

  /// Havuzdan düşmüş bir kelimeyi tekrar açık büfe havuzuna iade eder
  Future<bool> returnWordToBuffetPool(int wordId) async {
    final activePlan = state.dailyPlan;
    if (activePlan == null || !activePlan.isOpenBuffet) return false;

    if (_apiService != null) {
      try {
        final updated = await _apiService.returnWordToBuffetPool(activePlan.id, wordId);
        if (updated != null) {
          _updatePlanInState(updated);
          return true;
        }
      } catch (e) {
        dev.log('QuizController.returnWordToBuffetPool error: $e');
      }
    }

    final newCompleted = List<dynamic>.from(activePlan.completedWordIds)..remove(wordId);
    final localUpdated = activePlan.copyWith(completedWordIds: newCompleted);
    _updatePlanInState(localUpdated);
    return true;
  }

  void _updatePlanInState(DailyQuizPlanModel updated) {
    final updatedAllPlans = state.allPlans.map((p) => p.id == updated.id ? updated : p).toList();
    _storageService?.saveCachedDailyPlan(updated);
    state = state.copyWith(
      dailyPlan: updated,
      allPlans: updatedAllPlans,
      isDailyQuizCompletedToday: updated.isCompletedToday(_formatTodayDate()),
    );
  }

  Future<bool> resetPlanProgress([String? planId]) async {
    final targetId = planId ?? state.dailyPlan?.id;
    if (targetId == null || targetId.isEmpty) return false;

    if (_apiService != null) {
      try {
        final updated = await _apiService.resetPlan(targetId);
        if (updated != null) {
          _updatePlanInState(updated);
          return true;
        }
      } catch (e) {
        dev.log('QuizController.resetPlanProgress error: $e');
      }
    }

    if (state.dailyPlan != null && state.dailyPlan!.id == targetId) {
      final reset = state.dailyPlan!.copyWith(
        currentPointer: 0,
        completedWordIds: const [],
        dailySelectedWordIds: const [],
        lastCompletedDate: null,
        streakDays: 0,
      );
      _updatePlanInState(reset);
      return true;
    }
    return false;
  }

  Future<bool> deleteDailyPlan({String? planId}) async {
    state = state.copyWith(errorMessage: null);
    final targetId = planId ?? state.dailyPlan?.id;

    if (_apiService != null) {
      try {
        await _apiService.deletePlan(planId: targetId);
      } catch (e) {
        dev.log('QuizController.deleteDailyPlan error: $e');
        state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        );
        return false;
      }
    }

    final remainingAll = state.allPlans.where((p) => p.id != targetId).toList();
    DailyQuizPlanModel? nextDailyPlan;
    if (remainingAll.isNotEmpty) {
      nextDailyPlan = remainingAll.firstWhere((p) => p.isActive, orElse: () => remainingAll.first);
      await _storageService?.saveCachedDailyPlan(nextDailyPlan);
    } else {
      await _storageService?.clearCachedDailyPlan();
    }

    state = state.copyWith(
      dailyPlan: nextDailyPlan,
      allPlans: remainingAll,
      clearDailyPlan: nextDailyPlan == null,
      isDailyQuizCompletedToday: nextDailyPlan != null && nextDailyPlan.isCompletedToday(_formatTodayDate()),
      hasPlanLoadError: false,
    );
    return true;
  }

  void startDailyQuizForToday() {
    final plan = state.dailyPlan;
    if (plan == null || plan.isPlanFinished) return;

    List<dynamic> batchIds;
    if (plan.isOpenBuffet) {
      if (plan.dailySelectedWordIds.isEmpty) return;
      batchIds = plan.dailySelectedWordIds;
    } else {
      final start = plan.currentPointer;
      final end = min(start + plan.dailyCount, plan.totalWords);
      if (start >= end) return;
      batchIds = plan.shuffledWordIds.sublist(start, end);
    }

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

    final title = plan.isOpenBuffet
        ? '${plan.displayTitle} (Bugünün Quizi)'
        : 'Günün Quizi (Gün ${plan.currentDay}/${plan.totalDays})';

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
      allPlans: state.allPlans,
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
      allPlans: state.allPlans,
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
    final historyEntry = QuizHistoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      title: state.quizTitle,
      score: state.score,
      maxScore: state.maxScore,
      totalQuestions: state.totalQuestions,
      correctCount: state.correctCount,
      wrongCount: state.wrongCount,
      isDailyQuiz: state.isDailyQuiz,
      results: state.results,
    );

    // Save history to Cloud API
    if (_historyApiService != null) {
      try {
        await _historyApiService.saveHistory(historyEntry);
      } catch (e) {
        dev.log('QuizController._saveCompletedQuiz history API error: $e');
      }
    }

    DailyQuizPlanModel? updatedPlan = state.dailyPlan;
    if (state.isDailyQuiz && state.dailyPlan != null) {
      final plan = state.dailyPlan!;
      final todayStr = _formatTodayDate();
      final newStreak = plan.streakDays + 1;
      final planIdInt = int.tryParse(plan.id);

      if (plan.isOpenBuffet) {
        final newlyCompleted = plan.dailySelectedWordIds.isNotEmpty
            ? plan.dailySelectedWordIds
            : state.results.map((r) => r.word.id).toList();
        final updatedCompleted = <dynamic>{...plan.completedWordIds, ...newlyCompleted}.toList();

        if (_apiService != null) {
          try {
            final cloudPlan = await _apiService.updateProgress(
              planId: planIdInt,
              newPointer: 0,
              lastCompletedDate: todayStr,
              streakDays: newStreak,
              completedWordIds: newlyCompleted,
            );
            if (cloudPlan != null) {
              updatedPlan = cloudPlan;
            } else {
              updatedPlan = plan.copyWith(
                completedWordIds: updatedCompleted,
                lastCompletedDate: todayStr,
                streakDays: newStreak,
              );
            }
          } catch (e) {
            dev.log('QuizController._saveCompletedQuiz buffet progress error: $e');
            updatedPlan = plan.copyWith(
              completedWordIds: updatedCompleted,
              lastCompletedDate: todayStr,
              streakDays: newStreak,
            );
          }
        } else {
          updatedPlan = plan.copyWith(
            completedWordIds: updatedCompleted,
            lastCompletedDate: todayStr,
            streakDays: newStreak,
          );
        }
      } else {
        // Sequential mode
        final newPointer = min(plan.currentPointer + state.totalQuestions, plan.totalWords);
        if (_apiService != null) {
          try {
            final cloudPlan = await _apiService.updateProgress(
              planId: planIdInt,
              newPointer: newPointer,
              lastCompletedDate: todayStr,
              streakDays: newStreak,
            );
            if (cloudPlan != null) {
              updatedPlan = cloudPlan;
            } else {
              updatedPlan = plan.copyWith(
                currentPointer: newPointer,
                lastCompletedDate: todayStr,
                streakDays: newStreak,
              );
            }
          } catch (e) {
            dev.log('QuizController._saveCompletedQuiz plan progress API error: $e');
            updatedPlan = plan.copyWith(
              currentPointer: newPointer,
              lastCompletedDate: todayStr,
              streakDays: newStreak,
            );
          }
        } else {
          updatedPlan = plan.copyWith(
            currentPointer: newPointer,
            lastCompletedDate: todayStr,
            streakDays: newStreak,
          );
        }
      }
    }

    // Refresh history from Cloud API
    List<QuizHistoryModel> updatedHistory = [historyEntry, ...state.historyList];
    if (_historyApiService != null) {
      try {
        final cloudHistory = await _historyApiService.getHistory();
        if (cloudHistory.isNotEmpty) {
          updatedHistory = cloudHistory;
        }
      } catch (_) {}
    }

    if (updatedPlan != null) {
      await _storageService?.saveCachedDailyPlan(updatedPlan);
    }

    final updatedAllPlans = state.allPlans.map((p) {
      if (updatedPlan != null && p.id == updatedPlan.id) {
        return updatedPlan;
      }
      return p;
    }).toList();

    if (!mounted) return;
    state = state.copyWith(
      historyList: updatedHistory,
      dailyPlan: updatedPlan,
      allPlans: updatedAllPlans,
      isDailyQuizCompletedToday: state.isDailyQuiz ? true : state.isDailyQuizCompletedToday,
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
    _storageService?.clearCachedDailyPlan();
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
    if (_historyApiService != null) {
      try {
        await _historyApiService.clearHistory();
      } catch (e) {
        dev.log('QuizController.clearAllHistory error: $e');
      }
    }
    state = state.copyWith(historyList: []);
  }

  Future<void> clearGeneralHistory() async {
    if (_historyApiService != null) {
      try {
        await _historyApiService.clearHistory(isDailyQuiz: false);
      } catch (e) {
        dev.log('QuizController.clearGeneralHistory error: $e');
      }
    }
    final remaining = state.historyList.where((h) => h.isDailyQuiz).toList();
    state = state.copyWith(historyList: remaining);
  }

  Future<void> clearDailyHistory() async {
    if (_historyApiService != null) {
      try {
        await _historyApiService.clearHistory(isDailyQuiz: true);
      } catch (e) {
        dev.log('QuizController.clearDailyHistory error: $e');
      }
    }
    final remaining = state.historyList.where((h) => !h.isDailyQuiz).toList();
    state = state.copyWith(historyList: remaining);
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
