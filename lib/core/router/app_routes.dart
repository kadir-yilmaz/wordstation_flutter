/// WordStation uygulaması genelindeki tüm rota (route) yollarını
/// tek bir merkezde toplayan ve tip güvenliği sağlayan sınıf.
abstract class AppRoutes {
  // Auth rotaları
  static const String login = '/login';
  static const String register = '/register';

  // Ana uygulama sekmeleri (Branches)
  static const String words = '/words';
  static const String wordsStudy = '/words/study';

  static const String synonyms = '/synonyms';
  static const String synonymsStudy = '/synonyms/study';

  static const String quiz = '/quiz';
  static const String quizStudy = '/quiz/study';
  static const String quizHistory = '/quiz-history';

  static const String plan = '/plan';
  static const String planStudy = '/plan/study';

  static const String profile = '/profile';

  // Modal / Form / Yardımcı rotalar
  static const String addWord = '/add-word';
  static const String tokenInspector = '/token-inspector';

  // Geriye dönük uyumluluk
  static const String study = '/study';
}
