import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordstation_flutter/core/services/sound_service.dart';
import 'package:wordstation_flutter/core/storage/secure_storage_service.dart';
import 'package:wordstation_flutter/features/auth/models/login_request.dart';
import 'package:wordstation_flutter/features/auth/models/token_response.dart';
import 'package:wordstation_flutter/features/auth/models/user_model.dart';
import 'package:wordstation_flutter/features/quiz/controllers/quiz_controller.dart';
import 'package:wordstation_flutter/features/quiz/models/daily_quiz_plan_model.dart';
import 'package:wordstation_flutter/features/quiz/models/quiz_history_model.dart';
import 'package:wordstation_flutter/features/quiz/pages/quiz_history_page.dart';
import 'package:wordstation_flutter/features/words/models/synonym_group_model.dart';
import 'package:wordstation_flutter/features/words/models/word_model.dart';
import 'package:wordstation_flutter/features/words/pages/study_session_page.dart';
import 'package:wordstation_flutter/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('Models Unit Tests', () {
    test('WordModel serialization and deserialization', () {
      final json = {
        'id': 1,
        'en': 'ubiquitous',
        'tr': 'her yerde bulunan',
        'example': 'Smartphones are ubiquitous.',
        'listName': 'Advanced',
        'userId': 42,
      };

      final word = WordModel.fromJson(json);
      expect(word.id, 1);
      expect(word.en, 'ubiquitous');
      expect(word.tr, 'her yerde bulunan');
      expect(word.example, 'Smartphones are ubiquitous.');
      expect(word.listName, 'Advanced');

      final serialized = word.toJson();
      expect(serialized['en'], 'ubiquitous');
      expect(serialized['tr'], 'her yerde bulunan');
      expect(serialized['listName'], 'Advanced');
    });

    test('WordModel PascalCase and casing tolerance', () {
      final json = {
        'Id': 10,
        'English': 'abandon',
        'Turkish': 'terk etmek',
        'Sentence': 'He abandoned the car.',
        'Category': 'B2',
      };

      final word = WordModel.fromJson(json);
      expect(word.id, 10);
      expect(word.en, 'abandon');
      expect(word.tr, 'terk etmek');
      expect(word.example, 'He abandoned the car.');
      expect(word.listName, 'B2');
    });

    test('SynonymGroupModel serialization', () {
      final json = {
        'turkish': 'hızlı',
        'words': [
          {'en': 'fast', 'tr': 'hızlı'},
          {'en': 'quick', 'tr': 'hızlı'},
          {'en': 'rapid', 'tr': 'hızlı'},
        ],
      };

      final group = SynonymGroupModel.fromJson(json);
      expect(group.turkishMeaning, 'hızlı');
      expect(group.words.length, 3);
      expect(group.words.first.en, 'fast');
    });

    test('LoginRequest and TokenResponse parsing', () {
      const loginReq = LoginRequest(email: 'test@wordstation.com', password: 'secretpassword');
      expect(loginReq.toJson()['email'], 'test@wordstation.com');

      final tokenJson = {
        'token': 'access_token_123',
        'refreshToken': 'refresh_token_456',
        'userId': 'user_99',
        'email': 'test@wordstation.com',
      };

      final tokenResp = TokenResponse.fromJson(tokenJson);
      expect(tokenResp.accessToken, 'access_token_123');
      expect(tokenResp.refreshToken, 'refresh_token_456');
      expect(tokenResp.userId, 'user_99');

      final user = UserModel(id: 'user_99', email: 'test@wordstation.com');
      expect(user.id, 'user_99');
      expect(user.email, 'test@wordstation.com');
    });

    test('QuizHistoryModel serialization and percentage', () {
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
        title: 'Günün Quizi',
        score: 90,
        maxScore: 100,
        totalQuestions: 10,
        correctCount: 9,
        wrongCount: 1,
        isDailyQuiz: true,
        results: [questionResult],
      );

      expect(history.percentage, 90);
      final json = history.toJson();
      expect(json['title'], 'Günün Quizi');
      expect(json['isDailyQuiz'], isTrue);

      final parsed = QuizHistoryModel.fromJson(json);
      expect(parsed.score, 90);
      expect(parsed.results.length, 1);
      expect(parsed.results.first.isCorrect, isTrue);
    });
    test('DailyQuizPlanModel zero-repeat pointer math and progression', () {
      final plan = DailyQuizPlanModel(
        id: 'plan_1',
        listName: 'B1 Kelimeler',
        shuffledWordIds: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], // 14 words
        currentPointer: 0,
        dailyCount: 5,
        streakDays: 1,
        createdAt: DateTime(2026, 8, 16),
        lastCompletedDate: '2026-08-15',
        isEnglishToTurkish: true,
      );

      expect(plan.totalDays, 3);
      expect(plan.currentDay, 1);
      expect(plan.nextBatchCount, 5);
      expect(plan.remainingWords, 14);
      expect(plan.progressRatio, 0.0);
      expect(plan.isPlanFinished, isFalse);

      // Advance pointer by 5 (Day 1 completed)
      final day2Plan = plan.copyWith(currentPointer: 5, lastCompletedDate: '2026-08-16');
      expect(day2Plan.currentDay, 2);
      expect(day2Plan.nextBatchCount, 5);
      expect(day2Plan.remainingWords, 9);
      expect(day2Plan.isCompletedToday('2026-08-16'), isTrue);

      // Advance pointer by 5 (Day 2 completed) -> 4 words remaining
      final day3Plan = day2Plan.copyWith(currentPointer: 10);
      expect(day3Plan.currentDay, 3);
      expect(day3Plan.nextBatchCount, 4); // Handles remaining 4 words smoothly
      expect(day3Plan.remainingWords, 4);
      expect(day3Plan.isPlanFinished, isFalse);

      // Day 3 completed -> All words done
      final finishedPlan = day3Plan.copyWith(currentPointer: 14);
      expect(finishedPlan.isPlanFinished, isTrue);
      expect(finishedPlan.remainingWords, 0);
      expect(finishedPlan.progressPercentage, 100);

      // Test serialization
      final json = plan.toJson();
      final fromJson = DailyQuizPlanModel.fromJson(json);
      expect(fromJson.id, plan.id);
      expect(fromJson.totalWords, 14);
      expect(fromJson.shuffledWordIds.length, 14);
    });
  });

  group('Quiz Controller Tests', () {
    test('Quiz generation and answer selection', () async {
      final sampleWords = [
        const WordModel(id: 1, en: 'apple', tr: 'elma'),
        const WordModel(id: 2, en: 'banana', tr: 'muz'),
        const WordModel(id: 3, en: 'orange', tr: 'portakal'),
        const WordModel(id: 4, en: 'grape', tr: 'üzüm'),
        const WordModel(id: 5, en: 'lemon', tr: 'limon'),
      ];

      final soundService = SoundService(enableAudio: false);
      final storage = SecureStorageService();
      final controller = QuizController(
        sampleWords,
        soundService: soundService,
        storage: storage,
      );
      controller.generateQuiz(questionCount: 4, englishToTurkish: true);

      expect(controller.state.questions.length, 4);
      expect(controller.state.currentIndex, 0);
      expect(controller.state.score, 0);

      final currentQ = controller.state.currentQuestion!;
      expect(currentQ.options.length, 4);
      expect(currentQ.options.contains(currentQ.correctAnswer), isTrue);

      await controller.selectAnswer(currentQ.correctAnswer, delay: Duration.zero);
      expect(controller.state.score, 10);
      expect(controller.state.results.length, 1);
      expect(controller.state.results.first.isCorrect, isTrue);
      expect(controller.state.currentIndex, 1);
    });

    test('Daily Quiz generation and title format', () {
      final sampleWords = [
        const WordModel(id: 1, en: 'apple', tr: 'elma'),
        const WordModel(id: 2, en: 'banana', tr: 'muz'),
        const WordModel(id: 3, en: 'orange', tr: 'portakal'),
        const WordModel(id: 4, en: 'grape', tr: 'üzüm'),
      ];

      final soundService = SoundService(enableAudio: false);
      final storage = SecureStorageService();
      final controller = QuizController(
        sampleWords,
        soundService: soundService,
        storage: storage,
      );
      controller.generateDailyQuiz(questionCount: 3);

      expect(controller.state.isDailyQuiz, isTrue);
      expect(controller.state.questions.length, 3);
      expect(controller.state.quizTitle.contains('Günün Quizi'), isTrue);
    });

    test('Isolated general vs daily history clear', () async {
      final sampleWords = [
        const WordModel(id: 1, en: 'apple', tr: 'elma'),
        const WordModel(id: 2, en: 'banana', tr: 'muz'),
      ];

      final soundService = SoundService(enableAudio: false);
      final storage = SecureStorageService();
      final controller = QuizController(
        sampleWords,
        soundService: soundService,
        storage: storage,
      );

      final generalItem = QuizHistoryModel(
        id: '1',
        date: DateTime.now(),
        title: 'Genel Test',
        score: 10,
        maxScore: 10,
        totalQuestions: 1,
        correctCount: 1,
        wrongCount: 0,
        isDailyQuiz: false,
        results: const [],
      );

      final dailyItem = QuizHistoryModel(
        id: '2',
        date: DateTime.now(),
        title: 'Günlük Test',
        score: 10,
        maxScore: 10,
        totalQuestions: 1,
        correctCount: 1,
        wrongCount: 0,
        isDailyQuiz: true,
        results: const [],
      );

      // Seed state
      controller.state = controller.state.copyWith(
        historyList: [generalItem, dailyItem],
      );

      expect(controller.state.historyList.length, 2);

      // Clear general history only
      await controller.clearGeneralHistory();
      expect(controller.state.historyList.length, 1);
      expect(controller.state.historyList.first.isDailyQuiz, isTrue);

      // Clear daily history
      await controller.clearDailyHistory();
      expect(controller.state.historyList.length, 0);
    });
  });

  testWidgets('QuizHistoryPage renders compact rows and handles empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuizHistoryPage(
            isDailyQuiz: true,
            title: 'Günlük Quiz Sonuçları',
          ),
        ),
      ),
    );

    expect(find.text('Günlük Quiz Sonuçları'), findsOneWidget);
    expect(find.text('Henüz Çözülmüş Test Yok'), findsOneWidget);
  });

  testWidgets('StudySessionPage handles keyboard shortcuts and flips card', (WidgetTester tester) async {
    const testWord1 = WordModel(id: 1, en: 'ephemeral', tr: 'geçici', listName: 'B2');
    const testWord2 = WordModel(id: 2, en: 'ubiquitous', tr: 'her yerde bulunan', listName: 'B2');

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StudySessionPage(
            words: [testWord1, testWord2],
            listTitle: 'B2',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ephemeral'), findsOneWidget);

    // Flip card with ArrowUp
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(find.text('geçici'), findsOneWidget);

    // Next word with ArrowRight
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('ubiquitous'), findsOneWidget);

    // Prev word with ArrowLeft
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('ephemeral'), findsOneWidget);

    // Toggle Random with ArrowDown
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
  });

  testWidgets('WordStationApp smoke test with pump', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WordStationApp(),
      ),
    );

    // Initial frame
    expect(find.text('WordStation'), findsWidgets);

    // Advance time past the splash timer
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
