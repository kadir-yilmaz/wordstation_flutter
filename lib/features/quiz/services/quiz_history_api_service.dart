// ignore_for_file: prefer_initializing_formals
import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/quiz_history_model.dart';

final quizHistoryApiServiceProvider = Provider<QuizHistoryApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return QuizHistoryApiService(apiClient: apiClient, storage: storage);
});

class QuizHistoryApiService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  QuizHistoryApiService({
    required ApiClient apiClient,
    required SecureStorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  Future<String?> _resolveUserId() async {
    return await _storage.getUserId() ?? await _storage.getUserEmail();
  }

  /// Kullanıcının test geçmişini API'den getirir.
  Future<List<QuizHistoryModel>> getHistory({bool? isDailyQuiz}) async {
    try {
      final userId = await _resolveUserId();
      final queryParams = <String, dynamic>{};
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }
      if (isDailyQuiz != null) {
        queryParams['isDailyQuiz'] = isDailyQuiz;
      }

      final response = await _apiClient.get(
        ApiConstants.quizHistory,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data is List ? response.data as List : [];
        return rawList
            .map((item) => QuizHistoryModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      dev.log('QuizHistoryApiService.getHistory DioException: ${e.response?.statusCode} -> ${e.message}');
      return [];
    } catch (e) {
      dev.log('QuizHistoryApiService.getHistory unexpected error: $e');
      return [];
    }
  }

  /// Tamamlanan testi buluta kaydeder.
  Future<QuizHistoryModel?> saveHistory(QuizHistoryModel history) async {
    try {
      final userId = await _resolveUserId();
      final payload = {
        'userId': userId,
        'date': history.date.toIso8601String(),
        'title': history.title,
        'score': history.score,
        'maxScore': history.maxScore,
        'totalQuestions': history.totalQuestions,
        'correctCount': history.correctCount,
        'wrongCount': history.wrongCount,
        'isDailyQuiz': history.isDailyQuiz,
        'results': history.results.map((r) => {
          'word': r.word.toJson(),
          'questionText': r.questionText,
          'correctAnswer': r.correctAnswer,
          'selectedAnswer': r.selectedAnswer,
          'isCorrect': r.isCorrect,
        }).toList(),
      };

      final response = await _apiClient.post(
        ApiConstants.quizHistory,
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        return QuizHistoryModel.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
      return null;
    } on DioException catch (e) {
      dev.log('QuizHistoryApiService.saveHistory DioException: ${e.response?.statusCode} -> ${e.message}');
      return null;
    } catch (e) {
      dev.log('QuizHistoryApiService.saveHistory unexpected error: $e');
      return null;
    }
  }

  /// Kullanıcının test geçmişini API'den siler.
  Future<bool> clearHistory({bool? isDailyQuiz}) async {
    try {
      final userId = await _resolveUserId();
      final queryParams = <String, dynamic>{};
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }
      if (isDailyQuiz != null) {
        queryParams['isDailyQuiz'] = isDailyQuiz;
      }

      final response = await _apiClient.delete(
        ApiConstants.quizHistory,
        queryParameters: queryParams,
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } on DioException catch (e) {
      dev.log('QuizHistoryApiService.clearHistory DioException: ${e.response?.statusCode} -> ${e.message}');
      return false;
    } catch (e) {
      dev.log('QuizHistoryApiService.clearHistory unexpected error: $e');
      return false;
    }
  }
}
