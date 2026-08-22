import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/quiz/models/daily_quiz_plan_model.dart';
import '../utils/jwt_decoder.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  // 🌐 Sadece WEB için In-Memory (RAM) Değişkenleri
  // LocalStorage'a hassas JWT token'ları ASLA yazılmaz (0 XSS Riski).
  // Sayfa yenilendiğinde sıfırlanır, Silent Refresh mekanizması ile kurtarılır.
  static String? _inMemoryAccessToken;
  static String? _inMemoryUserId;
  static String? _inMemoryUserEmail;

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

  // Persistent cache keys
  static const String _keyDailyQuizPlanCache = 'cached_daily_quiz_plan';

  // Legacy keys for cleanup
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
    final effectiveEmail = email ?? _getEmailFromJwt(accessToken);
    final effectiveUserId = (effectiveEmail != null && effectiveEmail.isNotEmpty)
        ? effectiveEmail
        : (userId ?? _getUserIdFromJwt(accessToken));

    if (kIsWeb) {
      // 🌐 WEB: Token'ları yalnızca RAM'de tut
      _inMemoryAccessToken = accessToken;
      _inMemoryUserId = effectiveUserId;
      _inMemoryUserEmail = effectiveEmail;
    } else {
      // 📱 MOBIL / DESKTOP: Donanımsal kasaya yaz
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);

      if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
        await _storage.write(key: _keyUserId, value: effectiveUserId);
      }

      if (effectiveEmail != null && effectiveEmail.isNotEmpty) {
        await _storage.write(key: _keyUserEmail, value: effectiveEmail);
      }
    }
  }

  // Getters
  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      return _inMemoryAccessToken;
    }
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      // 🌐 WEB: Refresh Token HttpOnly Cookie içinde tarayıcı tarafından tutulur
      return null;
    }
    return await _storage.read(key: _keyRefreshToken);
  }

  // Exact Swift ApiAuthService logic: var resolvedUserId: String? { email ?? userId }
  Future<String?> getUserId() async {
    if (kIsWeb) {
      if (_inMemoryUserEmail != null && _inMemoryUserEmail!.isNotEmpty) {
        return _inMemoryUserEmail;
      }
      if (_inMemoryUserId != null && _inMemoryUserId!.isNotEmpty) {
        return _inMemoryUserId;
      }
      if (_inMemoryAccessToken != null) {
        final emailFromJwt = _getEmailFromJwt(_inMemoryAccessToken!);
        if (emailFromJwt != null && emailFromJwt.isNotEmpty) return emailFromJwt;
        final idFromJwt = _getUserIdFromJwt(_inMemoryAccessToken!);
        if (idFromJwt != null && idFromJwt.isNotEmpty) return idFromJwt;
      }
      return null;
    }

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
    if (kIsWeb) {
      if (_inMemoryUserEmail != null && _inMemoryUserEmail!.isNotEmpty) {
        return _inMemoryUserEmail;
      }
      if (_inMemoryAccessToken != null) {
        final emailFromJwt = _getEmailFromJwt(_inMemoryAccessToken!);
        if (emailFromJwt != null && emailFromJwt.isNotEmpty) {
          _inMemoryUserEmail = emailFromJwt;
          return emailFromJwt;
        }
      }
      return null;
    }

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
    final claims = JwtDecoder.decode(token);
    return (claims['email'] ??
            claims['nameid'] ??
            claims['sub'] ??
            claims['userId'] ??
            claims['id'] ??
            claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'])
        ?.toString();
  }

  String? _getEmailFromJwt(String token) {
    final claims = JwtDecoder.decode(token);
    return (claims['email'] ??
            claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'])
        ?.toString();
  }

  // Theme Mode (Hassas olmayan kullanıcı tercihi web'de de saklanabilir)
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

  // Persistent Cache for Daily Quiz Plan
  Future<void> saveCachedDailyPlan(DailyQuizPlanModel plan) async {
    try {
      final jsonStr = jsonEncode(plan.toJson());
      await _storage.write(key: _keyDailyQuizPlanCache, value: jsonStr);
    } catch (e) {
      debugPrint('SecureStorageService.saveCachedDailyPlan error: $e');
    }
  }

  Future<DailyQuizPlanModel?> getCachedDailyPlan() async {
    try {
      final jsonStr = await _storage.read(key: _keyDailyQuizPlanCache);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr);
        if (map is Map<String, dynamic>) {
          return DailyQuizPlanModel.fromJson(map);
        }
      }
    } catch (e) {
      debugPrint('SecureStorageService.getCachedDailyPlan error: $e');
    }
    return null;
  }

  Future<void> clearCachedDailyPlan() async {
    try {
      await _storage.delete(key: _keyDailyQuizPlanCache);
    } catch (e) {
      debugPrint('SecureStorageService.clearCachedDailyPlan error: $e');
    }
  }

  // Clear all tokens and leftover legacy cache on Logout
  Future<void> clearAll() async {
    if (kIsWeb) {
      _inMemoryAccessToken = null;
      _inMemoryUserId = null;
      _inMemoryUserEmail = null;
    }
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyDailyQuizPlanCache);
    await _storage.delete(key: _keyQuizHistory);
    await _storage.delete(key: _keyDailyQuizDate);
    await _storage.delete(key: _keyDailyQuizPlan);
  }
}

