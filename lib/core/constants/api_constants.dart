import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://wsapi.runasp.net';

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String googleLogin = '/api/auth/google-login';
  static const String refreshToken = '/api/auth/refresh-token';
  static const String revokeToken = '/api/auth/revoke-token';

  // Words endpoints
  static const String words = '/api/words';
  static const String userWords = '/api/words/user';
  static const String lists = '/api/words/lists';
  static const String search = '/api/words/search';
  static const String synonymGroups = '/api/words/synonym-groups';

  // Daily Quiz & Quiz History endpoints
  static const String dailyQuiz = '/api/dailyquiz';
  static const String dailyQuizProgress = '/api/dailyquiz/progress';
  static const String quizHistory = '/api/quizhistory';

  static String wordById(dynamic id) => '/api/words/$id';
  static String wordsByUserId(String userId) => '/api/words/user/$userId';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}

class GoogleAuthConstants {
  GoogleAuthConstants._();

  static const String iosClientId =
      '276618571409-ssancomdsfpbnbtp3nvvh1om3iv4odqm.apps.googleusercontent.com';
  static const String androidClientId =
      '276618571409-ab968vnnog57q3dldma2r9nadperm53d.apps.googleusercontent.com';
  static const String webClientId =
      '276618571409-4fsiaaab85ctjbfqvb4pg5mqnluh84rr.apps.googleusercontent.com';
  static const String desktopClientId =
      '276618571409-j079peo6q2sd1gg2s77cq3rop72s56ia.apps.googleusercontent.com';
  static const String desktopClientSecret = String.fromEnvironment(
    'DESKTOP_CLIENT_SECRET',
    defaultValue: '',
  );

  /// On iOS/macOS returns Apple Client ID, on Web returns Web Client ID, on Windows/Linux returns Desktop Client ID.
  static String? get clientId {
    if (kIsWeb) return webClientId;
    if (Platform.isIOS || Platform.isMacOS) return iosClientId;
    if (Platform.isWindows || Platform.isLinux) return desktopClientId;
    return null;
  }

  /// serverClientId should be null when relying on native client authentication
  static String? get serverClientId => null;
}
