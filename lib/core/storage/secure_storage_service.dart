import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/quiz/models/daily_quiz_plan_model.dart';
import '../../features/quiz/models/quiz_history_model.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyQuizHistory = 'quiz_history';
  static const String _keyDailyQuizDate = 'daily_quiz_date';
  static const String _keyDailyQuizPlan = 'daily_quiz_plan';

  // Save all tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? email,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    
    // In Swift: var resolvedUserId: String? { email ?? userId }
    final effectiveEmail = email ?? _getEmailFromJwt(accessToken);
    final effectiveUserId = (effectiveEmail != null && effectiveEmail.isNotEmpty)
        ? effectiveEmail
        : (userId ?? _getUserIdFromJwt(accessToken));

    if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
      await _storage.write(key: _keyUserId, value: effectiveUserId);
    }

    if (effectiveEmail != null && effectiveEmail.isNotEmpty) {
      await _storage.write(key: _keyUserEmail, value: effectiveEmail);
    }
  }

  // Getters
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  // Exact Swift ApiAuthService logic: var resolvedUserId: String? { email ?? userId }
  Future<String?> getUserId() async {
    final email = await getUserEmail();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    final savedId = await _storage.read(key: _keyUserId);
    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }
    final token = await getAccessToken();
    if (token != null) {
      final emailFromJwt = _getEmailFromJwt(token);
      if (emailFromJwt != null && emailFromJwt.isNotEmpty) {
        return emailFromJwt;
      }
      final idFromJwt = _getUserIdFromJwt(token);
      if (idFromJwt != null && idFromJwt.isNotEmpty) {
        return idFromJwt;
      }
    }
    return null;
  }

  Future<String?> getUserEmail() async {
    final savedEmail = await _storage.read(key: _keyUserEmail);
    if (savedEmail != null && savedEmail.isNotEmpty) {
      return savedEmail;
    }
    final token = await getAccessToken();
    if (token != null) {
      final emailFromJwt = _getEmailFromJwt(token);
      if (emailFromJwt != null && emailFromJwt.isNotEmpty) {
        await _storage.write(key: _keyUserEmail, value: emailFromJwt);
        return emailFromJwt;
      }
    }
    return null;
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  String? _getUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded);
      if (map is Map) {
        return (map['email'] ??
                map['nameid'] ??
                map['sub'] ??
                map['userId'] ??
                map['id'] ??
                map['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'])
            ?.toString();
      }
    } catch (_) {}
    return null;
  }

  String? _getEmailFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded);
      if (map is Map) {
        return (map['email'] ??
                map['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'])
            ?.toString();
      }
    } catch (_) {}
    return null;
  }

  // Theme Mode
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _storage.write(key: _keyThemeMode, value: mode.name);
  }

  Future<ThemeMode> getThemeMode() async {
    final modeStr = await _storage.read(key: _keyThemeMode);
    if (modeStr == ThemeMode.dark.name) {
      return ThemeMode.dark;
    } else if (modeStr == ThemeMode.light.name) {
      return ThemeMode.light;
    }
    // Default to Light theme
    return ThemeMode.light;
  }

  // Quiz History
  Future<void> saveQuizHistory(QuizHistoryModel history) async {
    try {
      final currentList = await getQuizHistoryList();
      final updatedList = [history, ...currentList];
      // Keep last 50 attempts
      if (updatedList.length > 50) {
        updatedList.removeRange(50, updatedList.length);
      }
      final jsonStr = jsonEncode(updatedList.map((h) => h.toJson()).toList());
      await _storage.write(key: _keyQuizHistory, value: jsonStr);
    } catch (_) {}
  }

  Future<List<QuizHistoryModel>> getQuizHistoryList() async {
    try {
      final jsonStr = await _storage.read(key: _keyQuizHistory);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        final list = <QuizHistoryModel>[];
        for (final item in decoded) {
          try {
            if (item is Map) {
              list.add(QuizHistoryModel.fromJson(
                  Map<String, dynamic>.from(item)));
            }
          } catch (e) {
            debugPrint('Failed to parse a quiz history item: $e');
          }
        }
        return list;
      }
    } catch (e) {
      debugPrint('getQuizHistoryList error: $e');
    }
    return [];
  }

  Future<void> saveQuizHistoryList(List<QuizHistoryModel> list) async {
    try {
      final jsonStr = jsonEncode(list.map((h) => h.toJson()).toList());
      await _storage.write(key: _keyQuizHistory, value: jsonStr);
    } catch (_) {}
  }

  Future<void> clearQuizHistory() async {
    await _storage.delete(key: _keyQuizHistory);
  }

  // Daily Quiz Tracking
  Future<String?> getDailyQuizDate() async {
    return await _storage.read(key: _keyDailyQuizDate);
  }

  Future<void> saveDailyQuizDate(String dateStr) async {
    await _storage.write(key: _keyDailyQuizDate, value: dateStr);
  }

  // Daily Quiz Plan (Zero-Repeat Engine)
  Future<void> saveDailyQuizPlan(DailyQuizPlanModel plan) async {
    try {
      final jsonStr = jsonEncode(plan.toJson());
      await _storage.write(key: _keyDailyQuizPlan, value: jsonStr);
    } catch (e) {
      debugPrint('saveDailyQuizPlan error: $e');
    }
  }

  Future<DailyQuizPlanModel?> getDailyQuizPlan() async {
    try {
      final jsonStr = await _storage.read(key: _keyDailyQuizPlan);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr);
      if (map is Map) {
        return DailyQuizPlanModel.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (e) {
      debugPrint('getDailyQuizPlan error: $e');
    }
    return null;
  }

  Future<void> deleteDailyQuizPlan() async {
    await _storage.delete(key: _keyDailyQuizPlan);
  }

  // Clear only auth tokens on Logout (PRESERVES quiz history, daily plan, and theme mode)
  Future<void> clearAll() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserEmail);
  }
}
