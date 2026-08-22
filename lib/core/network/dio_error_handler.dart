import 'package:dio/dio.dart';

/// Centralized helper to extract meaningful, human-friendly error messages
/// from Dio exceptions across all API calls in the application.
class DioErrorHandler {
  DioErrorHandler._();

  static String extractMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Bağlantı zaman aşımına uğradı. Lütfen internetinizi kontrol edin.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.';
    }

    if (e.response?.data != null) {
      final dynamic data = e.response!.data;
      if (data is Map) {
        // 1. Detailed field validation errors (e.g. ASP.NET ModelState errors)
        if (data['errors'] != null) {
          final dynamic errors = data['errors'];
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
        if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
          return data['message'].toString();
        }
        if (data['error'] != null && data['error'].toString().trim().isNotEmpty) {
          return data['error'].toString();
        }
        if (data['detail'] != null && data['detail'].toString().trim().isNotEmpty) {
          return data['detail'].toString();
        }
        if (data['title'] != null && data['title'].toString().trim().isNotEmpty) {
          return data['title'].toString();
        }
      } else if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
    }

    if (e.response?.statusCode == 401) {
      return 'Oturum süreniz doldu veya giriş bilgileri hatalı.';
    }
    if (e.response?.statusCode == 400) {
      return 'Geçersiz istek. Lütfen bilgilerinizi kontrol edin.';
    }
    if (e.response?.statusCode == 403) {
      return 'Bu işlem için yetkiniz bulunmamaktadır.';
    }
    if (e.response?.statusCode == 404) {
      return 'İstenen kaynak bulunamadı.';
    }
    if (e.response?.statusCode == 409) {
      return 'Bu kayıt zaten mevcut veya çakışma oluştu.';
    }
    if (e.response?.statusCode == 500) {
      return 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.';
    }

    return 'Bir hata oluştu (${e.response?.statusCode ?? "Ağ"}). Lütfen tekrar deneyin.';
  }

  /// Checks if an error is specifically caused by network connection / timeout / offline.
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('connection refused') ||
        str.contains('network is unreachable') ||
        str.contains('handshakeexception') ||
        str.contains('bağlantı') ||
        str.contains('internet');
  }
}
