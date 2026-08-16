import 'dart:developer';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/login_request.dart';
import '../models/token_response.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return AuthService(apiClient: apiClient, storage: storage);
});

class AuthService {
  final ApiClient apiClient;
  final SecureStorageService storage;
  final GoogleSignIn _googleSignIn;

  AuthService({
    required this.apiClient,
    required this.storage,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email'],
              clientId: GoogleAuthConstants.clientId,
              serverClientId: GoogleAuthConstants.serverClientId,
            );

  // Email/Password Login
  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      log('🔵 [AuthService.loginWithEmail] Attempting login for $email...');
      final request = LoginRequest(email: email.trim(), password: password);
      final response = await apiClient.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      log('🟢 [AuthService.loginWithEmail] Login response: status=${response.statusCode}');

      if (response.data != null) {
        final tokenResponse = TokenResponse.fromJson(
          response.data is Map<String, dynamic>
              ? response.data
              : Map<String, dynamic>.from(response.data as Map),
        );

        final userEmail = tokenResponse.email ?? email.trim();
        // In Swift: var resolvedUserId: String? { email ?? userId }
        final userId = userEmail;

        await storage.saveTokens(
          accessToken: tokenResponse.accessToken,
          refreshToken: tokenResponse.refreshToken,
          userId: userId,
          email: userEmail,
        );

        log('🟢 [AuthService.loginWithEmail] Tokens saved successfully for userId: $userId');

        return UserModel(
          id: userId,
          email: userEmail,
        );
      } else {
        throw Exception('Geçersiz sunucu yanıtı.');
      }
    } on DioException catch (e) {
      log('🔴 [AuthService.loginWithEmail] DioException: status=${e.response?.statusCode}, data=${e.response?.data}');
      final message = _extractErrorMessage(e);
      throw Exception(message);
    } catch (e, stack) {
      log('🔴 [AuthService.loginWithEmail] Exception: $e\n$stack');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Register
  Future<UserModel> register(String email, String password) async {
    try {
      log('🔵 [AuthService.register] Registering new user: $email...');
      final response = await apiClient.post(
        ApiConstants.register,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      log('🟢 [AuthService.register] Register response: status=${response.statusCode}');

      // If register returns tokens, save them. Otherwise, log in automatically.
      if (response.data != null &&
          (response.data['token'] != null || response.data['accessToken'] != null)) {
        final tokenResponse = TokenResponse.fromJson(
          response.data is Map<String, dynamic>
              ? response.data
              : Map<String, dynamic>.from(response.data as Map),
        );

        final userEmail = tokenResponse.email ?? email.trim();
        final userId = userEmail;

        await storage.saveTokens(
          accessToken: tokenResponse.accessToken,
          refreshToken: tokenResponse.refreshToken,
          userId: userId,
          email: userEmail,
        );

        return UserModel(
          id: userId,
          email: userEmail,
        );
      }

      // If register only created the user, log in now
      return await loginWithEmail(email, password);
    } on DioException catch (e) {
      log('🔴 [AuthService.register] DioException: status=${e.response?.statusCode}, data=${e.response?.data}');
      final message = _extractErrorMessage(e);
      throw Exception(message);
    } catch (e, stack) {
      log('🔴 [AuthService.register] Exception: $e\n$stack');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Google OAuth 2.0 Login (Exact Swift GoogleLoginRequest matching)
  Future<UserModel> loginWithGoogle() async {
    try {
      final platformName = kIsWeb ? 'web' : Platform.operatingSystem;
      log('🔵 [AuthService.loginWithGoogle] Starting Google Sign-In on $platformName...');
      log('🔵 [AuthService.loginWithGoogle] Config: clientId=${GoogleAuthConstants.clientId}, serverClientId=${GoogleAuthConstants.serverClientId}');

      // Disconnect previous session to allow fresh account selection
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        log('⚪ [AuthService.loginWithGoogle] Pre-signout note: $signOutError');
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        log('🟡 [AuthService.loginWithGoogle] User cancelled Google Sign-In popup/dialog.');
        throw Exception('Google ile giriş iptal edildi.');
      }

      log('🟢 [AuthService.loginWithGoogle] Account selected: email=${googleUser.email}, displayName=${googleUser.displayName}, id=${googleUser.id}');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken ?? '';
      final accessToken = googleAuth.accessToken ?? '';

      log('🟢 [AuthService.loginWithGoogle] Tokens received: hasIdToken=${idToken.isNotEmpty} (len=${idToken.length}), hasAccessToken=${accessToken.isNotEmpty}');

      // Swift GoogleLoginRequest parameters: email, googleId, name
      final payload = {
        'email': googleUser.email,
        'googleId': googleUser.id,
        'name': googleUser.displayName ?? '',
        'idToken': idToken,
        'accessToken': accessToken,
      };

      log('🔵 [AuthService.loginWithGoogle] Sending payload to ${ApiConstants.googleLogin}...');

      final response = await apiClient.post(
        ApiConstants.googleLogin,
        data: payload,
      );

      log('🟢 [AuthService.loginWithGoogle] Backend response: status=${response.statusCode}, data=${response.data}');

      if (response.data != null) {
        final tokenResponse = TokenResponse.fromJson(
          response.data is Map<String, dynamic>
              ? response.data
              : Map<String, dynamic>.from(response.data as Map),
        );

        final userEmail = tokenResponse.email ?? googleUser.email;
        final userId = userEmail;

        await storage.saveTokens(
          accessToken: tokenResponse.accessToken,
          refreshToken: tokenResponse.refreshToken,
          userId: userId,
          email: userEmail,
        );

        log('🟢 [AuthService.loginWithGoogle] Login completed successfully for user: $userEmail');

        return UserModel(
          id: userId,
          email: userEmail,
          displayName: googleUser.displayName,
        );
      } else {
        throw Exception('Google girişi sonrası geçersiz sunucu yanıtı.');
      }
    } on PlatformException catch (e) {
      log('🔴 [AuthService.loginWithGoogle] PlatformException: code=${e.code}, message=${e.message}, details=${e.details}');
      if (e.code == 'sign_in_failed') {
        if (e.message != null && e.message!.contains('10')) {
          throw Exception(
              'Google Giriş Hatası (ApiException 10): Android SHA-1 parmak izi veya Paket Adı Google Cloud Console ile eşleşmedi. Lütfen Google Cloud ayarlarını kontrol edin.');
        } else if (e.message != null && e.message!.contains('12500')) {
          throw Exception(
              'Google Giriş Hatası (ApiException 12500): Google Play Services hesabı doğrulayamadı.');
        }
      }
      throw Exception('Google ile giriş başarısız oldu: ${e.message ?? e.code}');
    } on DioException catch (e) {
      log('🔴 [AuthService.loginWithGoogle] DioException: status=${e.response?.statusCode}, data=${e.response?.data}');
      final message = _extractErrorMessage(e);
      throw Exception(message);
    } catch (e, stack) {
      log('🔴 [AuthService.loginWithGoogle] Exception: $e\n$stack');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Logout
  Future<void> logout() async {
    log('🔵 [AuthService.logout] Logging out user...');
    try {
      final token = await storage.getAccessToken();
      if (token != null) {
        await apiClient.post(ApiConstants.revokeToken);
      }
    } catch (_) {}

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await storage.clearAll();
    log('🟢 [AuthService.logout] User logged out and local storage cleared.');
  }

  String _extractErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Bağlantı zaman aşımına uğradı. Lütfen internetinizi kontrol edin.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.';
    }

    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        // 1. Detailed field validation errors (e.g. ASP.NET ModelState errors)
        if (data['errors'] != null) {
          final errors = data['errors'];
          if (errors is Map) {
            final msgs = <String>[];
            errors.forEach((k, v) {
              if (v is List) {
                msgs.addAll(v.map((item) => item.toString()));
              } else {
                msgs.add(v.toString());
              }
            });
            if (msgs.isNotEmpty) return msgs.join('\n');
          }
          return errors.toString();
        }
        // 2. Specific message / error descriptions
        if (data['message'] != null) return data['message'].toString();
        if (data['error'] != null) return data['error'].toString();
        if (data['detail'] != null) return data['detail'].toString();
        if (data['title'] != null) return data['title'].toString();
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    }

    if (e.response?.statusCode == 401) {
      return 'E-posta veya şifre hatalı.';
    }
    if (e.response?.statusCode == 400) {
      return 'Geçersiz istek. Lütfen bilgilerinizi kontrol edin.';
    }
    if (e.response?.statusCode == 409) {
      return 'Bu e-posta adresi ile zaten bir hesap mevcut.';
    }

    return 'Bir hata oluştu (${e.response?.statusCode ?? "Bilinmeyen"}). Lütfen tekrar deneyin.';
  }
}
