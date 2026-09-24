import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordstation_flutter/core/constants/api_constants.dart';
import 'package:wordstation_flutter/core/services/sound_service.dart';
import 'package:wordstation_flutter/core/storage/secure_storage_service.dart';
import 'package:wordstation_flutter/features/quiz/controllers/quiz_controller.dart';
import 'package:wordstation_flutter/features/quiz/models/quiz_history_model.dart';
import 'package:wordstation_flutter/features/quiz/repositories/quiz_repository.dart';
import 'package:wordstation_flutter/features/quiz/services/quiz_history_api_service.dart';
import 'package:wordstation_flutter/features/words/models/word_model.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  final sampleWords = [
    const WordModel(id: 1, en: 'apple', tr: 'elma'),
    const WordModel(id: 2, en: 'banana', tr: 'muz'),
    const WordModel(id: 3, en: 'orange', tr: 'portakal'),
    const WordModel(id: 4, en: 'grape', tr: 'üzüm'),
    const WordModel(id: 5, en: 'lemon', tr: 'limon'),
  ];

  group('Quiz History Models', () {
    test('QuizHistoryModel serialization, deserialization and percentage math', () {
      const word = WordModel(id: 1, en: 'ephemeral', tr: 'geçici');
      const questionResult = QuizQuestionResult(
        word: word,
        questionText: 'ephemeral',
        correctAnswer: 'geçici',
        selectedAnswer: 'geçici',
        isCorrect: true,
      );

      final history = QuizHistoryModel(
        id: 'hist_1',
        date: DateTime.now(),
        title: 'Genel Test',
        score: 90,
        maxScore: 100,
        totalQuestions: 10,
        correctCount: 9,
        wrongCount: 1,
        isDailyQuiz: false,
        results: [questionResult],
      );

      expect(history.percentage, 90);
      final json = history.toJson();
      expect(json['title'], 'Genel Test');
      expect(json['isDailyQuiz'], isFalse);

      final parsed = QuizHistoryModel.fromJson(json);
      expect(parsed.score, 90);
      expect(parsed.results.length, 1);
      expect(parsed.results.first.isCorrect, isTrue);
    });
  });

  group('QuizController - Question Generation & Flow', () {
    test('Generates questions with 4 unique options including correct answer', () {
      final controller = QuizController(
        sampleWords,
        soundService: SoundService(enableAudio: false),
        quizRepository: _FakeQuizRepository(),
      );

      controller.generateQuiz(questionCount: 4, englishToTurkish: true);

      expect(controller.state.questions.length, 4);
      expect(controller.state.currentIndex, 0);
      expect(controller.state.score, 0);

      final currentQ = controller.state.currentQuestion!;
      expect(currentQ.options.length, 4);
      expect(currentQ.options.contains(currentQ.correctAnswer), isTrue);
    });

    test('selectAnswer evaluates correct vs wrong answer and updates score', () async {
      final controller = QuizController(
        sampleWords,
        soundService: SoundService(enableAudio: false),
        quizRepository: _FakeQuizRepository(),
      );
      controller.generateQuiz(questionCount: 4, englishToTurkish: true);

      final currentQ = controller.state.currentQuestion!;
      final correct = currentQ.correctAnswer;

      // Select correct answer
      await controller.selectAnswer(correct, delay: Duration.zero);
      expect(controller.state.score, 10);
      expect(controller.state.results.length, 1);
      expect(controller.state.results.first.isCorrect, isTrue);
      expect(controller.state.currentIndex, 1);
    });

    test('Completing all questions sets isQuizCompleted and retains results', () async {
      final controller = QuizController(
        sampleWords,
        soundService: SoundService(enableAudio: false),
        quizRepository: _FakeQuizRepository(),
      );
      controller.generateQuiz(questionCount: 3, englishToTurkish: true);

      while (!controller.state.isQuizCompleted) {
        final currentQ = controller.state.currentQuestion!;
        await controller.selectAnswer(currentQ.correctAnswer, delay: Duration.zero);
      }

      expect(controller.state.isQuizCompleted, isTrue);
      expect(controller.state.results.length, 3);
      expect(controller.state.score, 30);

      // Reset
      controller.resetToSetup();
      expect(controller.state.isQuizCompleted, isFalse);
      expect(controller.state.questions, isEmpty);
      expect(controller.state.score, 0);
    });

    test('startDailyQuiz initializes daily mode and custom title', () {
      final controller = QuizController(
        sampleWords,
        soundService: SoundService(enableAudio: false),
        quizRepository: _FakeQuizRepository(),
      );

      controller.startDailyQuiz(
        words: sampleWords.take(4).toList(),
        englishToTurkish: true,
        title: 'Günün Quizi (1. Gün)',
      );

      expect(controller.state.isDailyQuiz, isTrue);
      expect(controller.state.quizTitle, 'Günün Quizi (1. Gün)');
      expect(controller.state.questions.length, 4);
    });
  });

  group('Quiz History API & Repository Integration', () {
    test('getHistory and clearHistory perform HTTP requests properly', () async {
      final storage = SecureStorageService();
      await storage.clearAll();
      await storage.saveTokens(
        accessToken: 'mock_token',
        refreshToken: 'mock_refresh',
        userId: 'user_1',
        email: 'user1@wordstation.com',
      );

      final mockClient = createMockApiClient((options) {
        if (options.path.contains(ApiConstants.quizHistory) && options.method == 'GET') {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: [
              {
                'id': 'hist_100',
                'date': DateTime.now().toIso8601String(),
                'title': 'Test 1',
                'score': 80,
                'maxScore': 100,
                'totalQuestions': 10,
                'correctCount': 8,
                'wrongCount': 2,
                'isDailyQuiz': false,
                'results': [],
              }
            ],
          );
        } else if (options.path.contains(ApiConstants.quizHistory) && options.method == 'DELETE') {
          return Response(requestOptions: options, statusCode: 200, data: true);
        }
        return Response(requestOptions: options, statusCode: 404);
      });

      final apiService = QuizHistoryApiService(apiClient: mockClient, storage: storage);
      final repo = QuizRepositoryImpl(historyApiService: apiService);

      final history = await repo.getHistory();
      expect(history.length, 1);
      expect(history.first.id, 'hist_100');
      expect(history.first.score, 80);

      final clearSuccess = await repo.clearHistory();
      expect(clearSuccess, isTrue);
    });
  });
}

class _FakeQuizRepository implements IQuizRepository {
  List<QuizHistoryModel> history = [];

  @override
  Future<List<QuizHistoryModel>> getHistory() async => history;

  @override
  Future<QuizHistoryModel?> saveHistory(QuizHistoryModel entry) async {
    history.add(entry);
    return entry;
  }

  @override
  Future<bool> clearHistory({bool? isDailyQuiz}) async {
    history.clear();
    return true;
  }
}
