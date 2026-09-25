// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../quiz/controllers/quiz_controller.dart';
import '../../quiz/models/quiz_history_model.dart';
import '../../words/controllers/word_list_controller.dart';
import '../../words/models/word_model.dart';
import '../models/daily_plan_day_model.dart';
import '../models/daily_quiz_plan_model.dart';
import '../repositories/plan_repository.dart';

// ─── Plan State ─────────────────────────────────────────────────────────────

class PlanState {
  final DailyQuizPlanModel? dailyPlan;
  final List<DailyPlanDayModel> dailyPlanDays;
  final bool isDailyQuizCompletedToday;
  final bool hasPlanLoadError;
  final bool isPlanLoaded;
  final String? errorMessage;

  const PlanState({
    this.dailyPlan,
    this.dailyPlanDays = const [],
    this.isDailyQuizCompletedToday = false,
    this.hasPlanLoadError = false,
    this.isPlanLoaded = false,
    this.errorMessage,
  });

  factory PlanState.initial() => const PlanState();

  PlanState copyWith({
    DailyQuizPlanModel? dailyPlan,
    bool clearDailyPlan = false,
    List<DailyPlanDayModel>? dailyPlanDays,
    bool? isDailyQuizCompletedToday,
    bool? hasPlanLoadError,
    bool? isPlanLoaded,
    String? errorMessage,
  }) {
    return PlanState(
      dailyPlan: clearDailyPlan ? null : (dailyPlan ?? this.dailyPlan),
      dailyPlanDays:
          clearDailyPlan ? const [] : (dailyPlanDays ?? this.dailyPlanDays),
      isDailyQuizCompletedToday:
          isDailyQuizCompletedToday ?? this.isDailyQuizCompletedToday,
      hasPlanLoadError: hasPlanLoadError ?? this.hasPlanLoadError,
      isPlanLoaded: isPlanLoaded ?? this.isPlanLoaded,
      errorMessage: errorMessage,
    );
  }
}

// ─── Plan Controller ────────────────────────────────────────────────────────

final planControllerProvider =
    StateNotifierProvider<PlanController, PlanState>((ref) {
  final planRepository = ref.watch(planRepositoryProvider);
  final initialWords = ref.read(wordListControllerProvider).words;

  final controller = PlanController(
    initialWords,
    planRepository: planRepository,
  );

  // Update words pool gracefully
  ref.listen<WordListState>(wordListControllerProvider, (prev, next) {
    controller.updateWordsPool(next.words);
  });

  // Listen to Auth State changes
  ref.listen<AuthState>(authControllerProvider, (prev, next) {
    if (next.isAuthenticated) {
      controller.loadPlanData();
    } else if (next.status == AuthStatus.unauthenticated) {
      controller.reset();
    }
  });

  // Listen to Daily Quiz completion exactly once
  ref.listen<QuizState>(quizControllerProvider, (prev, next) {
    if (next.isDailyQuiz && next.isQuizCompleted && prev?.isQuizCompleted != true) {
      controller.onDailyQuizCompleted(
        totalQuestions: next.totalQuestions,
        correctCount: next.correctCount,
        wrongCount: next.wrongCount,
        score: next.score,
        maxScore: next.maxScore,
        results: next.results,
      );
    }
  });

  return controller;
});

class PlanController extends StateNotifier<PlanState> {
  List<WordModel> _allWords;
  final IPlanRepository _planRepository;
  bool _isSavingProgress = false;

  PlanController(
    this._allWords, {
    required IPlanRepository planRepository,
  })  : _planRepository = planRepository,
        super(PlanState.initial()) {
    loadPlanData();
  }

  void updateWordsPool(List<WordModel> words) {
    _allWords = List<WordModel>.from(words);
  }

  /// Aynı güne ait mükerrer kayıtları temizler (en son tamamlanan kaydı tutar)
  static List<DailyPlanDayModel> deduplicateDays(List<DailyPlanDayModel> days) {
    final Map<int, DailyPlanDayModel> map = {};
    for (final day in days) {
      final existing = map[day.dayNumber];
      if (existing == null ||
          day.completedAt.isAfter(existing.completedAt) ||
          day.id > existing.id) {
        map[day.dayNumber] = day;
      }
    }
    final sorted = map.values.toList()
      ..sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
    return sorted;
  }

  /// Plan verilerini API'den yükler.
  Future<void> loadPlanData() async {
    final todayStr = _formatTodayDate();

    DailyQuizPlanModel? cloudPlan;
    List<DailyPlanDayModel> planDays = [];
    bool isDailyDone = false;
    bool hasPlanError = false;
    String? errorMsg;

    try {
      cloudPlan = await _planRepository.getActivePlan();
      if (cloudPlan != null) {
        isDailyDone = cloudPlan.isCompletedToday(todayStr);
        final allDays = await _planRepository.getPlanDays();
        final planIdInt = int.tryParse(cloudPlan.id) ?? 0;
        final rawDays = allDays.where((d) => d.dailyQuizPlanId == planIdInt).toList();
        planDays = deduplicateDays(rawDays);
      }
    } catch (e) {
      hasPlanError = true;
      errorMsg = e.toString().replaceAll('Exception: ', '');
      dev.log('PlanController.loadPlanData error: $e');
    }

    if (!mounted) return;

    state = state.copyWith(
      dailyPlan: cloudPlan,
      dailyPlanDays: cloudPlan != null ? planDays : const [],
      clearDailyPlan: cloudPlan == null && !hasPlanError,
      isDailyQuizCompletedToday:
          cloudPlan != null ? isDailyDone : state.isDailyQuizCompletedToday,
      hasPlanLoadError: hasPlanError,
      isPlanLoaded: true,
      errorMessage: errorMsg,
    );
  }

  /// Yeni bir plan oluşturur.
  Future<bool> createPlan({
    required String listName,
    required int dailyCount,
    required bool englishToTurkish,
  }) async {
    final matchingWords = (listName == 'Tümü' || listName == 'All')
        ? List<WordModel>.from(_allWords)
        : _allWords.where((w) => w.listName == listName).toList();

    if (matchingWords.isEmpty) {
      state =
          state.copyWith(errorMessage: 'Seçilen listede kelime bulunamadı.');
      return false;
    }

    try {
      final newPlan = await _planRepository.createPlan(
        listName: listName,
        dailyCount: dailyCount,
        englishToTurkish: englishToTurkish,
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
      state = state.copyWith(errorMessage: 'Plan oluşturulamadı.');
      return false;
    } catch (e) {
      dev.log('PlanController.createPlan error: $e');
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Mevcut planı siler.
  Future<bool> deleteDailyPlan() async {
    state = state.copyWith(errorMessage: null);

    try {
      await _planRepository.deletePlan();
    } catch (e) {
      dev.log('PlanController.deleteDailyPlan error: $e');
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }

    state = state.copyWith(
      clearDailyPlan: true,
      dailyPlanDays: const [],
      isDailyQuizCompletedToday: false,
      hasPlanLoadError: false,
    );
    return true;
  }

  /// Günlük quiz tamamlandığında plan ilerlemesini kaydeder.
  Future<void> onDailyQuizCompleted({
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
    required int score,
    required int maxScore,
    required List<QuizQuestionResult> results,
  }) async {
    final plan = state.dailyPlan;
    if (plan == null) return;
    if (_isSavingProgress) return;
    _isSavingProgress = true;

    try {
      final todayStr = _formatTodayDate();
      final newStreak = plan.streakDays + 1;
      final newPointer =
          min(plan.currentPointer + totalQuestions, plan.totalWords);
      final dayNumber = plan.currentDay;

      // 1. Günlük test sonucunu kaydet
      try {
        final resultsJson =
            jsonEncode(results.map((r) => r.toJson()).toList());
        await _planRepository.saveDayHistory(
          dayNumber: dayNumber,
          totalQuestions: totalQuestions,
          correctCount: correctCount,
          wrongCount: wrongCount,
          score: score,
          maxScore: maxScore,
          resultsJson: resultsJson,
        );
      } catch (e) {
        dev.log('PlanController.onDailyQuizCompleted saveDayHistory error: $e');
      }

      // 2. Plan ilerlemesini güncelle
      DailyQuizPlanModel? updatedPlan;
      try {
        updatedPlan = await _planRepository.updateProgress(
          newPointer: newPointer,
          lastCompletedDate: todayStr,
          streakDays: newStreak,
        );
      } catch (e) {
        dev.log(
            'PlanController.onDailyQuizCompleted updateProgress error: $e');
      }

      updatedPlan ??= plan.copyWith(
        currentPointer: newPointer,
        lastCompletedDate: todayStr,
        streakDays: newStreak,
      );

      // 3. Güncel geçmiş günleri çek ve mükerrerleri temizle
      final currentDayModel = DailyPlanDayModel(
        id: DateTime.now().millisecondsSinceEpoch,
        dailyQuizPlanId: int.tryParse(plan.id) ?? 0,
        dayNumber: dayNumber,
        completedAt: DateTime.now(),
        totalQuestions: totalQuestions,
        correctCount: correctCount,
        wrongCount: wrongCount,
        score: score,
        maxScore: maxScore,
        results: results,
      );

      List<DailyPlanDayModel> updatedDays = [
        currentDayModel,
        ...state.dailyPlanDays.where((d) => d.dayNumber != dayNumber),
      ];

      try {
        final cloudDays = await _planRepository.getPlanDays();
        if (cloudDays.isNotEmpty) {
          final planIdInt = int.tryParse(updatedPlan.id) ?? 0;
          final rawDays = cloudDays.where((d) => d.dailyQuizPlanId == planIdInt).toList();
          updatedDays = deduplicateDays(rawDays);
        }
      } catch (_) {}

      updatedDays = deduplicateDays(updatedDays);

      if (!mounted) return;
      state = state.copyWith(
        dailyPlan: updatedPlan,
        dailyPlanDays: updatedDays,
        isDailyQuizCompletedToday: true,
      );
    } finally {
      _isSavingProgress = false;
    }
  }

  /// Günlük quiz için kelimeleri hazırlar.
  /// QuizController'a iletilecek kelime listesini döner.
  List<WordModel>? getDailyQuizWords() {
    final plan = state.dailyPlan;
    if (plan == null || plan.isPlanFinished) return null;

    final start = plan.currentPointer;
    final end = min(start + plan.dailyCount, plan.totalWords);
    if (start >= end) return null;
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

    return selectedWords.isEmpty ? null : selectedWords;
  }

  void reset() {
    state = PlanState.initial();
    loadPlanData();
  }

  Future<void> clearDailyHistory() async {
    state = state.copyWith(dailyPlanDays: []);
  }

  Future<void> clearDailyPlan() async {
    try {
      await _planRepository.deletePlan();
    } catch (_) {}
    state = state.copyWith(clearDailyPlan: true);
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
