import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform, HttpServer, InternetAddress, ContentType;
import 'dart:math' show Random;
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/jwt_decoder.dart';
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

  // PKCE (Proof Key for Code Exchange - RFC 7636) Helper Methods
  static String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

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

        log('🟢 [AuthService.loginWithEmail] Login completed successfully for user: $userEmail');

        return UserModel(
          id: userId,
          email: userEmail,
        );
      } else {
        throw Exception('Geçersiz sunucu yanıtı.');
      }
    } on DioException catch (e) {
      log('🔴 [AuthService.loginWithEmail] DioException: ${e.message}, status=${e.response?.statusCode}, data=${e.response?.data}');
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      log('🔴 [AuthService.loginWithEmail] Unexpected error: $e');
      if (e.toString().startsWith('Exception: ')) {
        rethrow;
      }
      throw Exception('Giriş yapılırken beklenmeyen bir hata oluştu.');
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
    // Windows ve Linux'ta resmi google_sign_in eklentisinin yerel C++ uygulaması bulunmadığından,
    // Google'ın resmi Masaüstü standardı olan Loopback OAuth 2.0 akışı kullanılır.
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      return _loginWithGoogleDesktop();
    }

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

  // Manual Token Refresh (used by Auth Inspector page & manual triggers)
  Future<TokenResponse> refreshTokenManual() async {
    try {
      final currentToken = await storage.getAccessToken();
      final refreshToken = await storage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('Refresh token bulunamadı.');
      }

      log('🔵 [AuthService.refreshTokenManual] Requesting token refresh...');
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {
          'token': currentToken ?? '',
          'refreshToken': refreshToken,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final newAccessToken = (data['token'] ?? data['accessToken'] ?? '') as String;
        final newRefreshToken = (data['refreshToken'] ?? refreshToken) as String;
        final userId = data['userId']?.toString();
        final email = data['email']?.toString();

        if (newAccessToken.isNotEmpty) {
          await storage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            userId: userId,
            email: email,
          );

          log('🟢 [AuthService.refreshTokenManual] Token refreshed successfully.');

          return TokenResponse(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            userId: userId,
            email: email,
          );
        }
      }
      throw Exception('Geçersiz sunucu yanıtı.');
    } on DioException catch (e) {
      log('🔴 [AuthService.refreshTokenManual] DioException: $e');
      final message = _extractErrorMessage(e);
      throw Exception(message);
    } catch (e) {
      log('🔴 [AuthService.refreshTokenManual] Exception: $e');
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

  // Windows & Linux Desktop Loopback OAuth 2.0 Flow (RFC 8252)
  Future<UserModel> _loginWithGoogleDesktop() async {
    log('🔵 [AuthService._loginWithGoogleDesktop] Starting Loopback OAuth2 flow for Desktop...');
    HttpServer? server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      final redirectUri = 'http://localhost:$port';
      final clientId = GoogleAuthConstants.desktopClientId;

      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'access_type': 'offline',
      });

      log('🔵 [AuthService._loginWithGoogleDesktop] Opening browser with URL: $authUrl');
      final launched =
          await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Varsayılan web tarayıcısı açılamadı.');
      }

      // Wait for the redirect callback
      final request = await server.first.timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw Exception(
            'Google ile giriş zaman aşımına uğradı. Lütfen tekrar deneyin.'),
      );

      final queryParams = request.uri.queryParameters;
      final code = queryParams['code'];
      final error = queryParams['error'];

      // Send friendly response to the browser window
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>WordStation - Giriş Başarılı</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #121214; color: #FFFFFF; text-align: center; padding: 60px 20px; }
    .card { max-width: 420px; margin: 0 auto; background: #1E1E24; border-radius: 20px; padding: 36px 28px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
    h1 { color: #34C759; font-size: 24px; margin-bottom: 12px; }
    p { color: #8E8E93; font-size: 15px; line-height: 1.5; }
  </style>
</head>
<body>
  <div class="card">
    <h1>✓ Giriş Başarılı!</h1>
    <p>WordStation masaüstü uygulamasına dönebilirsiniz. Bu sekmeyi kapatabilirsiniz.</p>
  </div>
  <script>
    setTimeout(function() { window.close(); }, 2000);
  </script>
</body>
</html>
''');
      await request.response.close();

      if (error != null || code == null) {
        throw Exception(
            'Google ile giriş iptal edildi veya hata oluştu ($error).');
      }

      log('🟢 [AuthService._loginWithGoogleDesktop] Code received. Exchanging for tokens via PKCE...');

      // Exchange authorization code for tokens with Google using PKCE code_verifier (Zero secret!)
      final tokenDio = Dio();
      final tokenResponse = await tokenDio.post(
        'https://oauth2.googleapis.com/token',
        options: Options(contentType: Headers.formUrlEncodedContentType),
        data: {
          'client_id': clientId,
          if (GoogleAuthConstants.desktopClientSecret.isNotEmpty)
            'client_secret': GoogleAuthConstants.desktopClientSecret,
          'code': code,
          'code_verifier': codeVerifier,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );

      final tokenData = tokenResponse.data is Map<String, dynamic>
          ? tokenResponse.data
          : Map<String, dynamic>.from(tokenResponse.data as Map);

      final idToken = tokenData['id_token'] as String? ?? '';
      final accessToken = tokenData['access_token'] as String? ?? '';

      log('🟢 [AuthService._loginWithGoogleDesktop] Tokens obtained from Google. idToken len: ${idToken.length}');

      final decodedIdToken = JwtDecoder.decode(idToken);
      final email = decodedIdToken['email'] as String? ?? '';
      final googleId = decodedIdToken['sub'] as String? ?? '';
      final name = decodedIdToken['name'] as String? ?? '';

      final payload = {
        'email': email,
        'googleId': googleId,
        'name': name,
        'idToken': idToken,
        'accessToken': accessToken,
      };

      log('🔵 [AuthService._loginWithGoogleDesktop] Sending payload to ${ApiConstants.googleLogin}...');

      final response = await apiClient.post(
        ApiConstants.googleLogin,
        data: payload,
      );

      log('🟢 [AuthService._loginWithGoogleDesktop] Backend response: status=${response.statusCode}');

      if (response.data != null) {
        final backendTokenResponse = TokenResponse.fromJson(
          response.data is Map<String, dynamic>
              ? response.data
              : Map<String, dynamic>.from(response.data as Map),
        );

        final userEmail = backendTokenResponse.email ?? email;
        final userId = userEmail;

        await storage.saveTokens(
          accessToken: backendTokenResponse.accessToken,
          refreshToken: backendTokenResponse.refreshToken,
          userId: userId,
          email: userEmail,
        );

        log('🟢 [AuthService._loginWithGoogleDesktop] Login completed successfully for user: $userEmail');

        return UserModel(
          id: userId,
          email: userEmail,
          displayName: name,
        );
      } else {
        throw Exception('Google girişi sonrası geçersiz sunucu yanıtı.');
      }
    } on DioException catch (e) {
      log('🔴 [AuthService._loginWithGoogleDesktop] DioException: ${e.message}, status=${e.response?.statusCode}, data=${e.response?.data}');
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['error_description'] != null) {
          throw Exception('Google Giriş Hatası: ${data['error_description']}');
        }
      }
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      log('🔴 [AuthService._loginWithGoogleDesktop] Error: $e');
      if (e.toString().startsWith('Exception: ')) {
        rethrow;
      }
      throw Exception('Masaüstü Google girişi sırasında hata oluştu: $e');
    } finally {
      await server?.close(force: true);
    }
  }
}
