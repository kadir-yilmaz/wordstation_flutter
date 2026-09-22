import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/connectivity_service.dart';
import '../../../core/sync/sync_manager.dart';
import '../models/daily_plan_day_model.dart';
import '../models/daily_quiz_plan_model.dart';
import '../models/quiz_history_model.dart';
import '../services/daily_quiz_api_service.dart';
import '../services/quiz_history_api_service.dart';

abstract interface class IQuizRepository {
  Future<DailyQuizPlanModel?> getActivePlan({bool forceRefresh = false});
  Stream<DailyQuizPlanModel?> watchActivePlan();
  Future<List<DailyPlanDayModel>> getPlanDays(int planId, {bool forceRefresh = false});
  Future<List<QuizHistoryModel>> getHistory({bool forceRefresh = false});
  Future<DailyQuizPlanModel?> createPlan({
    required String listName,
    required int dailyCount,
    required bool englishToTurkish,
  });
  Future<bool> deletePlan(String? planId);
  Future<QuizHistoryModel?> submitDailyQuiz({
    int? planId,
    required int score,
    required int correctCount,
    required int wrongCount,
    required int totalQuestions,
    required int maxScore,
    List<QuizQuestionResult>? results,
  });
}

final quizRepositoryProvider = Provider<IQuizRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final apiService = ref.watch(dailyQuizApiServiceProvider);
  final historyApiService = ref.watch(quizHistoryApiServiceProvider);
  final syncManager = ref.watch(syncManagerProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  return QuizRepositoryImpl(
    db: db,
    apiService: apiService,
    historyApiService: historyApiService,
    syncManager: syncManager,
    connectivity: connectivity,
  );
});

class QuizRepositoryImpl implements IQuizRepository {
  final AppDatabase db;
  final DailyQuizApiService apiService;
  final QuizHistoryApiService historyApiService;
  final ISyncManager syncManager;
  final IConnectivityService connectivity;

  QuizRepositoryImpl({
    required this.db,
    required this.apiService,
    required this.historyApiService,
    required this.syncManager,
    required this.connectivity,
  });

  DailyQuizPlanModel _dataToPlanModel(DailyPlansTableData data) {
    List<int> wordIds = [];
    try {
      final decoded = jsonDecode(data.shuffledWordIdsJson);
      if (decoded is List) {
        wordIds = decoded.map((e) => (e as num).toInt()).toList();
      }
    } catch (_) {}

    return DailyQuizPlanModel(
      id: data.id,
      listName: data.listName,
      dailyCount: data.dailyCount,
      shuffledWordIds: wordIds,
      currentPointer: data.currentPointer,
      streakDays: data.streakDays,
      lastCompletedDate: data.lastCompletedDate,
      isEnglishToTurkish: data.isEnglishToTurkish,
      createdAt: data.createdAt,
    );
  }

  DailyPlansTableCompanion _planModelToCompanion(
    DailyQuizPlanModel model, {
    bool isSynced = true,
  }) {
    return DailyPlansTableCompanion(
      id: Value(model.id),
      listName: Value(model.listName),
      dailyCount: Value(model.dailyCount),
      shuffledWordIdsJson: Value(jsonEncode(model.shuffledWordIds)),
      currentPointer: Value(model.currentPointer),
      streakDays: Value(model.streakDays),
      lastCompletedDate: Value(model.lastCompletedDate),
      isEnglishToTurkish: Value(model.isEnglishToTurkish),
      isActive: const Value(true),
      isSynced: Value(isSynced),
      createdAt: Value(model.createdAt),
    );
  }

  DailyPlanDayModel _dataToDayModel(DailyPlanDaysTableData data) {
    List<QuizQuestionResult> results = [];
    try {
      final decoded = jsonDecode(data.resultsJson);
      if (decoded is List) {
        results = decoded
            .map((e) => QuizQuestionResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return DailyPlanDayModel(
      id: data.id,
      dailyQuizPlanId: data.dailyQuizPlanId,
      dayNumber: data.dayNumber,
      completedAt: data.completedAt,
      totalQuestions: data.totalQuestions,
      correctCount: data.correctCount,
      wrongCount: data.wrongCount,
      score: data.score,
      maxScore: data.maxScore,
      results: results,
    );
  }

  DailyPlanDaysTableCompanion _dayModelToCompanion(
    DailyPlanDayModel model, {
    bool isSynced = true,
  }) {
    return DailyPlanDaysTableCompanion(
      id: Value(model.id),
      dailyQuizPlanId: Value(model.dailyQuizPlanId),
      dayNumber: Value(model.dayNumber),
      completedAt: Value(model.completedAt),
      totalQuestions: Value(model.totalQuestions),
      correctCount: Value(model.correctCount),
      wrongCount: Value(model.wrongCount),
      score: Value(model.score),
      maxScore: Value(model.maxScore),
      resultsJson: Value(jsonEncode(model.results.map((r) => r.toJson()).toList())),
      isSynced: Value(isSynced),
    );
  }

  @override
  Stream<DailyQuizPlanModel?> watchActivePlan() {
    return db.watchActiveDailyPlan().map((data) {
      if (data == null) return null;
      return _dataToPlanModel(data);
    });
  }

  @override
  Future<DailyQuizPlanModel?> getActivePlan({bool forceRefresh = false}) async {
    final localData = await db.getActiveDailyPlan();
    final localPlan = localData != null ? _dataToPlanModel(localData) : null;

    if (localPlan != null && !forceRefresh) {
      unawaited(_silentSyncPlanFromRemote());
      return localPlan;
    }

    try {
      final remotePlan = await apiService.getPlan();
      if (remotePlan != null) {
        await db.upsertDailyPlan(_planModelToCompanion(remotePlan, isSynced: true));
        return remotePlan;
      }
      return localPlan;
    } catch (_) {
      return localPlan;
    }
  }

  Future<void> _silentSyncPlanFromRemote() async {
    if (!await connectivity.isOnline) return;
    try {
      final remotePlan = await apiService.getPlan();
      if (remotePlan != null) {
        await db.upsertDailyPlan(_planModelToCompanion(remotePlan, isSynced: true));
      }
    } catch (_) {}
  }

  @override
  Future<List<DailyPlanDayModel>> getPlanDays(
    int planId, {
    bool forceRefresh = false,
  }) async {
    final localData = await db.getDailyPlanDays(planId);
    final localDays = localData.map(_dataToDayModel).toList();

    if (localDays.isNotEmpty && !forceRefresh) {
      unawaited(_silentSyncPlanDays());
      return localDays;
    }

    try {
      final remoteDays = await apiService.getDayHistories();
      if (remoteDays.isNotEmpty) {
        final companions = remoteDays
            .map((d) => _dayModelToCompanion(d, isSynced: true))
            .toList();
        await db.upsertDailyPlanDays(companions);
        return remoteDays;
      }
      return localDays;
    } catch (_) {
      return localDays;
    }
  }

  Future<void> _silentSyncPlanDays() async {
    if (!await connectivity.isOnline) return;
    try {
      final remoteDays = await apiService.getDayHistories();
      if (remoteDays.isNotEmpty) {
        final companions = remoteDays
            .map((d) => _dayModelToCompanion(d, isSynced: true))
            .toList();
        await db.upsertDailyPlanDays(companions);
      }
    } catch (_) {}
  }

  @override
  Future<List<QuizHistoryModel>> getHistory({bool forceRefresh = false}) async {
    try {
      return await historyApiService.getHistory();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<DailyQuizPlanModel?> createPlan({
    required String listName,
    required int dailyCount,
    required bool englishToTurkish,
  }) async {
    final isOnline = await connectivity.isOnline;
    if (isOnline) {
      try {
        final created = await apiService.createOrResetPlan(
          listName: listName,
          dailyCount: dailyCount,
          isEnglishToTurkish: englishToTurkish,
        );
        if (created != null) {
          await db.upsertDailyPlan(_planModelToCompanion(created, isSynced: true));
          return created;
        }
      } catch (_) {}
    }

    // Offline plan creation
    final tempPlan = DailyQuizPlanModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      listName: listName,
      dailyCount: dailyCount,
      shuffledWordIds: const [],
      isEnglishToTurkish: englishToTurkish,
      createdAt: DateTime.now(),
    );

    await db.upsertDailyPlan(_planModelToCompanion(tempPlan, isSynced: false));
    await syncManager.enqueueAction('create_plan', {
      'listName': listName,
      'dailyCount': dailyCount,
      'englishToTurkish': englishToTurkish,
    });

    return tempPlan;
  }

  @override
  Future<bool> deletePlan(String? planId) async {
    if (planId != null) {
      await db.deleteDailyPlan(planId);
    } else {
      await db.clearAllDailyPlans();
    }

    final isOnline = await connectivity.isOnline;
    if (isOnline) {
      try {
        final ok = await apiService.deletePlan();
        if (ok) return true;
      } catch (_) {}
    }

    await syncManager.enqueueAction('delete_plan', {'planId': planId});
    return true;
  }

  @override
  Future<QuizHistoryModel?> submitDailyQuiz({
    int? planId,
    required int score,
    required int correctCount,
    required int wrongCount,
    required int totalQuestions,
    required int maxScore,
    List<QuizQuestionResult>? results,
  }) async {
    final resultsJson = jsonEncode(results?.map((r) => r.toJson()).toList() ?? []);

    final isOnline = await connectivity.isOnline;
    if (isOnline) {
      try {
        await apiService.saveDayHistory(
          dayNumber: 1,
          totalQuestions: totalQuestions,
          correctCount: correctCount,
          wrongCount: wrongCount,
          score: score,
          maxScore: maxScore,
          resultsJson: resultsJson,
        );
      } catch (_) {}
    }

    final offlineHistory = QuizHistoryModel(
      id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      title: 'Günlük Quiz',
      score: score,
      maxScore: maxScore,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      wrongCount: wrongCount,
      isDailyQuiz: true,
      results: results ?? const [],
    );

    // Update active plan in SQLite
    final activePlanData = await db.getActiveDailyPlan();
    if (activePlanData != null) {
      final currentPointer = activePlanData.currentPointer + totalQuestions;
      final streak = activePlanData.streakDays + 1;
      final updatedPlan = activePlanData.copyWith(
        currentPointer: currentPointer,
        streakDays: streak,
        lastCompletedDate: Value(DateTime.now().toIso8601String().split('T').first),
      );
      await db.upsertDailyPlan(updatedPlan.toCompanion(true));
    }

    if (!isOnline) {
      await syncManager.enqueueAction('submit_daily_quiz', {
        'dayNumber': 1,
        'totalQuestions': totalQuestions,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'score': score,
        'maxScore': maxScore,
        'resultsJson': resultsJson,
      });
    }

    return offlineHistory;
  }
}
