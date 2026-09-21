import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_handler.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/daily_plan_day_model.dart';
import '../models/daily_quiz_plan_model.dart';

final dailyQuizApiServiceProvider = Provider<DailyQuizApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return DailyQuizApiService(apiClient, storage);
});

class DailyQuizApiService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  DailyQuizApiService(this._apiClient, this._storage);

  /// Fetch daily quiz plan for current user from cloud
  Future<DailyQuizPlanModel?> getPlan() async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        log('DailyQuizApiService.getPlan: No userId available in storage.');
        return null;
      }

      final response = await _apiClient.get(
        ApiConstants.dailyQuiz,
        queryParameters: {'userId': userId},
      );

      if (response.data != null && response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        if (map.isNotEmpty && (map.containsKey('id') || map.containsKey('Id'))) {
          return DailyQuizPlanModel.fromJson(map);
        }
      }
      return null;
    } on DioException catch (e) {
      log('DailyQuizApiService.getPlan DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      if (e.response?.statusCode == 404 || e.response?.statusCode == 204) {
        return null;
      }
      throw Exception(DioErrorHandler.extractMessage(e));
    } catch (e) {
      log('DailyQuizApiService.getPlan Error: $e');
      rethrow;
    }
  }

  /// Create or reset daily quiz plan on cloud
  Future<DailyQuizPlanModel?> createOrResetPlan({
    required String listName,
    required int dailyCount,
    required bool isEnglishToTurkish,
  }) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Kullanıcı oturumu bulunamadı.');
      }

      final payload = <String, dynamic>{
        'UserId': userId,
        'ListName': listName,
        'DailyCount': dailyCount,
        'IsEnglishToTurkish': isEnglishToTurkish,
      };

      final response = await _apiClient.post(
        ApiConstants.dailyQuiz,
        data: payload,
      );

      if (response.data != null && response.data is Map) {
        return DailyQuizPlanModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return null;
    } on DioException catch (e) {
      log('DailyQuizApiService.createOrResetPlan DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      throw Exception(DioErrorHandler.extractMessage(e));
    }
  }

  /// Update daily quiz progress on cloud
  Future<DailyQuizPlanModel?> updateProgress({
    required int newPointer,
    required String lastCompletedDate,
    required int streakDays,
  }) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        log('DailyQuizApiService.updateProgress: No userId available.');
        return null;
      }

      final payload = <String, dynamic>{
        'UserId': userId,
        'NewPointer': newPointer,
        'LastCompletedDate': lastCompletedDate,
        'StreakDays': streakDays,
      };

      final response = await _apiClient.put(
        ApiConstants.dailyQuizProgress,
        data: payload,
      );

      if (response.data != null && response.data is Map) {
        return DailyQuizPlanModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return null;
    } on DioException catch (e) {
      log('DailyQuizApiService.updateProgress DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      return null;
    } catch (e) {
      log('DailyQuizApiService.updateProgress Error: $e');
      return null;
    }
  }

  /// Delete daily quiz plan on cloud
  Future<bool> deletePlan() async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return false;

      await _apiClient.delete(
        ApiConstants.dailyQuiz,
        queryParameters: {'userId': userId},
      );
      return true;
    } on DioException catch (e) {
      log('DailyQuizApiService.deletePlan DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      throw Exception(DioErrorHandler.extractMessage(e));
    } catch (e) {
      log('DailyQuizApiService.deletePlan Error: $e');
      rethrow;
    }
  }

  /// Get past day completions for the active plan directly from DB
  Future<List<DailyPlanDayModel>> getDayHistories() async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return [];

      final response = await _apiClient.get(
        ApiConstants.dailyQuizDays,
        queryParameters: {'userId': userId},
      );

      if (response.data != null && response.data is List) {
        return (response.data as List)
            .map((item) => DailyPlanDayModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      log('DailyQuizApiService.getDayHistories Error: $e');
      return [];
    }
  }

  /// Save completed daily quiz day directly into DB
  Future<DailyPlanDayModel?> saveDayHistory({
    required int dayNumber,
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
    required int score,
    required int maxScore,
    required String resultsJson,
  }) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return null;

      final payload = <String, dynamic>{
        'UserId': userId,
        'DayNumber': dayNumber,
        'TotalQuestions': totalQuestions,
        'CorrectCount': correctCount,
        'WrongCount': wrongCount,
        'Score': score,
        'MaxScore': maxScore,
        'ResultsJson': resultsJson,
      };

      final response = await _apiClient.post(
        ApiConstants.dailyQuizDays,
        data: payload,
      );

      if (response.data != null && response.data is Map) {
        return DailyPlanDayModel.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
      return null;
    } catch (e) {
      log('DailyQuizApiService.saveDayHistory Error: $e');
      return null;
    }
  }
}

