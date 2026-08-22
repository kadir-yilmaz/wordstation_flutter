import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  final SecureStorageService storage;
  final Dio dio;
  final void Function()? onUnauthorized;

  AuthInterceptor({
    required this.storage,
    required this.dio,
    this.onUnauthorized,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 🌐 Web ortamında CORS cookie iletimi için withCredentials'ı garanti et
    if (kIsWeb) {
      options.extra['withCredentials'] = true;
    }

    // Exclude auth public endpoints from requiring Authorization header if not needed
    final isAuthEndpoint = options.path.contains('/api/auth/login') ||
        options.path.contains('/api/auth/register') ||
        options.path.contains('/api/auth/google-login') ||
        options.path.contains('/api/auth/refresh-token');

    if (!isAuthEndpoint) {
      final token = await storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        log('AuthInterceptor: Request to ${options.path} with Bearer token (${token.substring(0, token.length > 10 ? 10 : token.length)}...)');
      } else {
        log('AuthInterceptor: Request to ${options.path} with NO TOKEN!');
      }
    }

    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final isAuthEndpoint = err.requestOptions.path.contains('/api/auth/login') ||
          err.requestOptions.path.contains('/api/auth/register') ||
          err.requestOptions.path.contains('/api/auth/google-login') ||
          err.requestOptions.path.contains('/api/auth/refresh-token');

      if (!isAuthEndpoint) {
        final currentToken = await storage.getAccessToken();
        final refreshToken = await storage.getRefreshToken();

        // 🌐 Web ortamında refresh token tarayıcı HttpOnly cookie'sindedir (refreshToken null olsa bile denenir)
        // 📱 Native ortamda ise kasadaki refreshToken aranır
        final canAttemptRefresh = kIsWeb || (refreshToken != null && refreshToken.isNotEmpty);

        if (canAttemptRefresh) {
          try {
            log('AuthInterceptor: 401 received. Attempting smart token refresh (kIsWeb=$kIsWeb)...');

            // Clean Dio instance to avoid recursive interception
            final refreshDio = Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                extra: kIsWeb ? {'withCredentials': true} : {},
              ),
            );

            final refreshData = <String, dynamic>{
              'token': currentToken ?? '',
            };
            if (!kIsWeb && refreshToken != null) {
              refreshData['refreshToken'] = refreshToken;
            }

            final response = await refreshDio.post(
              ApiConstants.refreshToken,
              data: refreshData,
              options: Options(
                extra: kIsWeb ? {'withCredentials': true} : {},
              ),
            );

            if (response.statusCode == 200 && response.data != null) {
              final data = response.data is Map<String, dynamic>
                  ? response.data
                  : Map<String, dynamic>.from(response.data as Map);

              final newAccessToken = (data['token'] ?? data['accessToken'] ?? '') as String;
              final newRefreshToken = (data['refreshToken'] ?? refreshToken ?? '') as String;
              final userId = data['userId']?.toString();
              final email = data['email']?.toString();

              if (newAccessToken.isNotEmpty) {
                await storage.saveTokens(
                  accessToken: newAccessToken,
                  refreshToken: newRefreshToken,
                  userId: userId,
                  email: email,
                );

                log('AuthInterceptor: Token refreshed successfully. Retrying original request.');

                // Clone request options and retry
                final requestOptions = err.requestOptions;
                requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                if (kIsWeb) {
                  requestOptions.extra['withCredentials'] = true;
                }

                final retryResponse = await dio.fetch(requestOptions);
                return handler.resolve(retryResponse);
              }
            }
          } catch (refreshErr) {
            log('AuthInterceptor: Token refresh failed: $refreshErr');
            await storage.clearAll();
            onUnauthorized?.call();
          }
        } else {
          await storage.clearAll();
          onUnauthorized?.call();
        }
      }
    }

    return handler.next(err);
  }
}

