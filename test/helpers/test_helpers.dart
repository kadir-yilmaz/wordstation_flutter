import 'package:dio/dio.dart';
import 'package:wordstation_flutter/core/network/api_client.dart';

/// Helper to create an ApiClient configured with an interceptor
/// that returns mock HTTP responses without making actual network calls.
ApiClient createMockApiClient(
  Response Function(RequestOptions options) responseHandler,
) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          final res = responseHandler(options);
          return handler.resolve(res);
        } catch (e) {
          if (e is DioException) {
            return handler.reject(e);
          }
          return handler.reject(
            DioException(
              requestOptions: options,
              error: e,
            ),
          );
        }
      },
    ),
  );
  return ApiClient(dio);
}
