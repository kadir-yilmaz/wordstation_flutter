import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/dio_error_handler.dart';
import '../models/daily_word_session.dart';

final dailyWordServiceProvider = Provider<DailyWordService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DailyWordService(apiClient);
});

class DailyWordService {
  final ApiClient _apiClient;

  DailyWordService(this._apiClient);

  Future<DailyWordSession?> getSession(String? userId, String listName) async {
    try {
      final response = await _apiClient.get(
        '/api/dailyword',
        queryParameters: {
          if (userId != null) 'userId': userId,
          'listName': listName,
        },
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return DailyWordSession.fromJson(response.data);
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      if (e is DioException) {
        throw Exception(DioErrorHandler.extractMessage(e));
      }
      throw Exception(e.toString());
    }
  }

  Future<DailyWordSession> initializeSession(String? userId, String listName) async {
    try {
      final response = await _apiClient.post(
        '/api/dailyword/init',
        data: {
          'userId': userId ?? '',
          'listName': listName,
        },
      );
      return DailyWordSession.fromJson(response.data);
    } catch (e) {
      if (e is DioException) throw Exception(DioErrorHandler.extractMessage(e));
      throw Exception(e.toString());
    }
  }

  Future<DailyWordSession> addToDaily(String? userId, String listName, List<int> wordIds) async {
    try {
      final response = await _apiClient.post(
        '/api/dailyword/add',
        data: {
          'userId': userId ?? '',
          'listName': listName,
          'wordIds': wordIds,
        },
      );
      return DailyWordSession.fromJson(response.data);
    } catch (e) {
      if (e is DioException) throw Exception(DioErrorHandler.extractMessage(e));
      throw Exception(e.toString());
    }
  }

  Future<DailyWordSession> removeFromDaily(String? userId, String listName, List<int> wordIds) async {
    try {
      final response = await _apiClient.post(
        '/api/dailyword/remove',
        data: {
          'userId': userId ?? '',
          'listName': listName,
          'wordIds': wordIds,
        },
      );
      return DailyWordSession.fromJson(response.data);
    } catch (e) {
      if (e is DioException) throw Exception(DioErrorHandler.extractMessage(e));
      throw Exception(e.toString());
    }
  }

  Future<DailyWordSession> completeWord(String? userId, String listName, int wordId) async {
    try {
      final response = await _apiClient.post(
        '/api/dailyword/complete',
        data: {
          'userId': userId ?? '',
          'listName': listName,
          'wordId': wordId,
        },
      );
      return DailyWordSession.fromJson(response.data);
    } catch (e) {
      if (e is DioException) throw Exception(DioErrorHandler.extractMessage(e));
      throw Exception(e.toString());
    }
  }

  Future<bool> deleteSession(String? userId, String listName) async {
    try {
      final response = await _apiClient.delete(
        '/api/dailyword',
        queryParameters: {
          if (userId != null) 'userId': userId,
          'listName': listName,
        },
      );
      return response.statusCode == 204;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return false;
      }
      if (e is DioException) throw Exception(DioErrorHandler.extractMessage(e));
      throw Exception(e.toString());
    }
  }
}
