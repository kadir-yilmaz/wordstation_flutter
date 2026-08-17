import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  // Clear all tokens and leftover legacy cache on Logout
  Future<void> clearAll() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyQuizHistory);
    await _storage.delete(key: _keyDailyQuizDate);
    await _storage.delete(key: _keyDailyQuizPlan);
  }
}
