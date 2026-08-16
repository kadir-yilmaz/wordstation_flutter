import 'dart:convert';

class JwtDecoder {
  JwtDecoder._();

  /// Decode JWT token payload (claims)
  static Map<String, dynamic> decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};

      final payload = _normalizeBase64(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded);

      if (map is Map<String, dynamic>) {
        return map;
      } else if (map is Map) {
        return Map<String, dynamic>.from(map);
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Decode JWT token header
  static Map<String, dynamic> getHeader(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};

      final header = _normalizeBase64(parts[0]);
      final decoded = utf8.decode(base64Url.decode(header));
      final map = jsonDecode(decoded);

      if (map is Map<String, dynamic>) {
        return map;
      } else if (map is Map) {
        return Map<String, dynamic>.from(map);
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Get expiration date from JWT 'exp' claim
  static DateTime? getExpirationDate(String token) {
    final decoded = decode(token);
    final exp = decoded['exp'];
    if (exp == null) return null;

    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true).toLocal();
    } else if (exp is String) {
      final parsedInt = int.tryParse(exp);
      if (parsedInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000, isUtc: true).toLocal();
      }
    }
    return null;
  }

  /// Check if token is expired
  static bool isExpired(String token) {
    final expDate = getExpirationDate(token);
    if (expDate == null) return false;
    return DateTime.now().isAfter(expDate);
  }

  /// Get remaining duration before expiration
  static Duration? getRemainingTime(String token) {
    final expDate = getExpirationDate(token);
    if (expDate == null) return null;
    final diff = expDate.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Format duration into readable timer format: HH:mm:ss
  static String formatDuration(Duration? duration) {
    if (duration == null) return '00:00:00';
    if (duration.isNegative || duration == Duration.zero) return 'Süresi Doldu';

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  /// Format Date into readable string: DD.MM.YYYY HH:mm:ss
  static String formatDate(DateTime? date) {
    if (date == null) return 'Bilinmiyor';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    final s = date.second.toString().padLeft(2, '0');
    return '$d.$m.$y $h:$min:$s';
  }

  static String _normalizeBase64(String str) {
    var output = str.replaceAll('-', '+').replaceAll('_', '/');
    while (output.length % 4 != 0) {
      output += '=';
    }
    return output;
  }
}
