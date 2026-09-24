import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_history_model.dart';
import '../services/quiz_history_api_service.dart';

/// Quiz Repository arayüzü — sadece genel quiz history işlemleri.
abstract interface class IQuizRepository {
  Future<List<QuizHistoryModel>> getHistory();
  Future<QuizHistoryModel?> saveHistory(QuizHistoryModel history);
  Future<bool> clearHistory({bool? isDailyQuiz});
}

final quizRepositoryProvider = Provider<IQuizRepository>((ref) {
  final historyApiService = ref.watch(quizHistoryApiServiceProvider);
  return QuizRepositoryImpl(historyApiService: historyApiService);
});

/// Online-only quiz repository — doğrudan API üzerinden çalışır.
class QuizRepositoryImpl implements IQuizRepository {
  final QuizHistoryApiService historyApiService;

  QuizRepositoryImpl({required this.historyApiService});

  @override
  Future<List<QuizHistoryModel>> getHistory() async {
    return await historyApiService.getHistory();
  }

  @override
  Future<QuizHistoryModel?> saveHistory(QuizHistoryModel history) async {
    return await historyApiService.saveHistory(history);
  }

  @override
  Future<bool> clearHistory({bool? isDailyQuiz}) async {
    return await historyApiService.clearHistory(isDailyQuiz: isDailyQuiz);
  }
}
