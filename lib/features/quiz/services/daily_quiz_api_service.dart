import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_handler.dart';
import '../../../core/storage/secure_storage_service.dart';
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

  /// Fetch active daily quiz plan for current user from cloud
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

  /// Fetch all plans for current user from cloud
  Future<List<DailyQuizPlanModel>> getAllPlans() async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        log('DailyQuizApiService.getAllPlans: No userId available.');
        return [];
      }

      final response = await _apiClient.get(
        ApiConstants.dailyQuizPlans,
        queryParameters: {'userId': userId},
      );

      if (response.data != null && response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((item) => DailyQuizPlanModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      log('DailyQuizApiService.getAllPlans DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      if (e.response?.statusCode == 404 || e.response?.statusCode == 204) {
        return [];
      }
      throw Exception(DioErrorHandler.extractMessage(e));
    } catch (e) {
      log('DailyQuizApiService.getAllPlans Error: $e');
      return [];
    }
  }

  /// Create a new plan on cloud
  Future<DailyQuizPlanModel?> createPlan({
    String? title,
    required String listName,
    required int dailyCount,
    required bool isEnglishToTurkish,
    PlanType planType = PlanType.sequential,
    List<dynamic>? shuffledWordIds,
    bool setAsActive = true,
  }) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Kullanıcı oturumu bulunamadı.');
      }

      final payload = <String, dynamic>{
        'UserId': userId,
        'Title': title ?? '',
        'ListName': listName,
        'PlanType': planType == PlanType.openBuffet ? 1 : 0,
        'DailyCount': dailyCount,
        'IsEnglishToTurkish': isEnglishToTurkish,
        'SetAsActive': setAsActive,
      };

      if (shuffledWordIds != null && shuffledWordIds.isNotEmpty) {
        payload['ShuffledWordIds'] = shuffledWordIds
            .map((id) => int.tryParse(id.toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
      }

      final response = await _apiClient.post(
        ApiConstants.dailyQuizPlans,
        data: payload,
      );

      if (response.data != null && response.data is Map) {
        return DailyQuizPlanModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return null;
    } on DioException catch (e) {
      log('DailyQuizApiService.createPlan DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Create or reset daily quiz plan on cloud (backward compatibility)
  Future<DailyQuizPlanModel?> createOrResetPlan({
    String? title,
    required String listName,
    required int dailyCount,
    required bool isEnglishToTurkish,
    PlanType planType = PlanType.sequential,
    List<dynamic>? shuffledWordIds,
  }) async {
    return createPlan(
      title: title,
      listName: listName,
      dailyCount: dailyCount,
      isEnglishToTurkish: isEnglishToTurkish,
      planType: planType,
      shuffledWordIds: shuffledWordIds,
      setAsActive: true,
    );
  }

  /// Set active plan on cloud
  Future<bool> setActivePlan(String planId) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return false;

      await _apiClient.post(
        ApiConstants.dailyQuizPlanActivate(planId),
        queryParameters: {'userId': userId},
      );
      return true;
    } on DioException catch (e) {
      log('DailyQuizApiService.setActivePlan DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      return false;
    } catch (e) {
      log('DailyQuizApiService.setActivePlan Error: $e');
      return false;
    }
  }

  /// Select words for Open Buffet mode for today
  Future<DailyQuizPlanModel?> selectBuffetWords(String planId, List<dynamic> wordIds) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return null;

      final parsedIds = wordIds
          .map((id) => int.tryParse(id.toString()) ?? 0)
          .where((id) => id > 0)
          .toList();

      final response = await _apiClient.post(
        ApiConstants.dailyQuizPlanBuffetWords(planId),
        data: {
          'UserId': userId,
          'SelectedWordIds': parsedIds,
        },
      );

      if (response.data != null && response.data is Map) {
        return DailyQuizPlanModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return null;
    } on DioException catch (e) {
      log('DailyQuizApiService.selectBuffetWords DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      log('DailyQuizApiService.selectBuffetWords Error: $e');
      rethrow;
    }
  }

  /// Return word back to Open Buffet pool
  Future<DailyQuizPlanModel?> returnWordToBuffetPool(String planId, int wordId) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return null;

      final response = await _apiClient.post(
        ApiConstants.dailyQuizPlanReturnWord(planId, wordId),
        queryParameters: {'userId': userId},
      );

      if (response.data != null && response.data is Map) {
        return DailyQuizPlanModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return null;
    } on DioException catch (e) {
      log('DailyQuizApiService.returnWordToBuffetPool DioException: ${e.response?.statusCode}');
      return null;
    } catch (e) {
      log('DailyQuizApiService.returnWordToBuffetPool Error: $e');
      return null;
    }
  }

  /// Update daily quiz progress on cloud
  Future<DailyQuizPlanModel?> updateProgress({
    int? planId,
    required int newPointer,
    required String lastCompletedDate,
    required int streakDays,
    List<dynamic>? completedWordIds,
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

      if (planId != null && planId > 0) {
        payload['PlanId'] = planId;
      }

      if (completedWordIds != null && completedWordIds.isNotEmpty) {
        payload['CompletedWordIds'] = completedWordIds
            .map((id) => int.tryParse(id.toString()) ?? 0)
            .where((id) => id > 0)
            .toList();
      }

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

  /// Reset plan progress on cloud
  Future<DailyQuizPlanModel?> resetPlan(String planId) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return null;

      final response = await _apiClient.put(
        ApiConstants.dailyQuizPlanReset(planId),
        queryParameters: {'userId': userId},
      );

      if (response.data != null && response.data is Map) {
        return DailyQuizPlanModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return null;
    } on DioException catch (e) {
      log('DailyQuizApiService.resetPlan DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      return null;
    } catch (e) {
      log('DailyQuizApiService.resetPlan Error: $e');
      return null;
    }
  }

  /// Delete daily quiz plan on cloud
  Future<bool> deletePlan({String? planId}) async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) return false;

      if (planId != null && planId.isNotEmpty) {
        await _apiClient.delete(
          ApiConstants.dailyQuizPlanById(planId),
          queryParameters: {'userId': userId},
        );
      } else {
        await _apiClient.delete(
          ApiConstants.dailyQuiz,
          queryParameters: {'userId': userId},
        );
      }
      return true;
    } on DioException catch (e) {
      log('DailyQuizApiService.deletePlan DioException: ${e.response?.statusCode} -> ${e.response?.data}');
      throw Exception(DioErrorHandler.extractMessage(e));
    } catch (e) {
      log('DailyQuizApiService.deletePlan Error: $e');
      rethrow;
    }
  }

  String _extractErrorMessage(DioException e) {
    return DioErrorHandler.extractMessage(e);
  }
}
