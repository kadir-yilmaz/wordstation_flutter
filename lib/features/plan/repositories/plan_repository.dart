import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_plan_day_model.dart';
import '../models/daily_quiz_plan_model.dart';
import '../services/daily_quiz_api_service.dart';

/// Plan Repository arayüzü — tüm plan CRUD işlemlerini tanımlar.
abstract interface class IPlanRepository {
  Future<DailyQuizPlanModel?> getActivePlan();
  Future<List<DailyPlanDayModel>> getPlanDays();
  Future<DailyQuizPlanModel?> createPlan({
    required String listName,
    required int dailyCount,
    required bool englishToTurkish,
  });
  Future<bool> deletePlan();
  Future<DailyQuizPlanModel?> updateProgress({
    required int newPointer,
    required String lastCompletedDate,
    required int streakDays,
  });
  Future<DailyPlanDayModel?> saveDayHistory({
    required int dayNumber,
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
    required int score,
    required int maxScore,
    required String resultsJson,
  });
}

final planRepositoryProvider = Provider<IPlanRepository>((ref) {
  final apiService = ref.watch(dailyQuizApiServiceProvider);
  return PlanRepositoryImpl(apiService: apiService);
});

/// Online-only plan repository — tüm işlemler doğrudan API üzerinden yapılır.
class PlanRepositoryImpl implements IPlanRepository {
  final DailyQuizApiService apiService;

  PlanRepositoryImpl({required this.apiService});

  @override
  Future<DailyQuizPlanModel?> getActivePlan() async {
    return await apiService.getPlan();
  }

  @override
  Future<List<DailyPlanDayModel>> getPlanDays() async {
    return await apiService.getDayHistories();
  }

  @override
  Future<DailyQuizPlanModel?> createPlan({
    required String listName,
    required int dailyCount,
    required bool englishToTurkish,
  }) async {
    return await apiService.createOrResetPlan(
      listName: listName,
      dailyCount: dailyCount,
      isEnglishToTurkish: englishToTurkish,
    );
  }

  @override
  Future<bool> deletePlan() async {
    return await apiService.deletePlan();
  }

  @override
  Future<DailyQuizPlanModel?> updateProgress({
    required int newPointer,
    required String lastCompletedDate,
    required int streakDays,
  }) async {
    return await apiService.updateProgress(
      newPointer: newPointer,
      lastCompletedDate: lastCompletedDate,
      streakDays: streakDays,
    );
  }

  @override
  Future<DailyPlanDayModel?> saveDayHistory({
    required int dayNumber,
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
    required int score,
    required int maxScore,
    required String resultsJson,
  }) async {
    return await apiService.saveDayHistory(
      dayNumber: dayNumber,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      wrongCount: wrongCount,
      score: score,
      maxScore: maxScore,
      resultsJson: resultsJson,
    );
  }
}
