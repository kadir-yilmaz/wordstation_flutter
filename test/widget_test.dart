import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordstation_flutter/core/services/sound_service.dart';
import 'package:wordstation_flutter/core/services/tts_service.dart';
import 'package:wordstation_flutter/core/storage/secure_storage_service.dart';
import 'package:wordstation_flutter/features/auth/models/login_request.dart';
import 'package:wordstation_flutter/features/auth/models/token_response.dart';
import 'package:wordstation_flutter/features/auth/models/user_model.dart';
import 'package:wordstation_flutter/features/quiz/controllers/quiz_controller.dart';
import 'package:wordstation_flutter/features/quiz/models/daily_quiz_plan_model.dart';
import 'package:wordstation_flutter/features/quiz/models/quiz_history_model.dart';
import 'package:wordstation_flutter/features/quiz/pages/daily_plan_page.dart';
import 'package:wordstation_flutter/features/quiz/pages/quiz_history_page.dart';
import 'package:wordstation_flutter/features/quiz/pages/quiz_page.dart';
import 'package:wordstation_flutter/features/words/controllers/study_controller.dart';
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

      const user = UserModel(id: 'user_99', email: 'test@wordstation.com');
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

    test('DailyQuizPlanModel parses backend .NET DTO response format', () {
      final backendJson = {
        'id': 12,
        'userId': 'user_guid_123',
        'listName': 'Advanced',
        'dailyCount': 10,
        'shuffledWordIds': [101, 102, 103, 104],
        'currentPointer': 2,
        'lastCompletedDate': '2026-08-17',
        'streakDays': 3,
        'isEnglishToTurkish': true,
        'createdAt': '2026-08-17T12:00:00Z',
        'updatedAt': '2026-08-17T12:00:00Z',
      };

      final plan = DailyQuizPlanModel.fromJson(backendJson);
      expect(plan.id, '12');
      expect(plan.listName, 'Advanced');
      expect(plan.dailyCount, 10);
      expect(plan.shuffledWordIds, [101, 102, 103, 104]);
      expect(plan.currentPointer, 2);
      expect(plan.lastCompletedDate, '2026-08-17');
      expect(plan.streakDays, 3);
      expect(plan.isEnglishToTurkish, isTrue);
    });

    test('DailyQuizPlanModel Open Buffet mode parsing, progression and computed properties', () {
      final buffetJson = {
        'id': 42,
        'title': 'YDS 2500 Açık Büfe',
        'listName': 'YDS',
        'planType': 1,
        'dailyCount': 50,
        'shuffledWordIds': List.generate(2500, (i) => i + 1),
        'completedWordIds': [1, 2, 3, 4, 5],
        'dailySelectedWordIds': [6, 7, 8],
        'currentPointer': 0,
        'streakDays': 5,
        'isEnglishToTurkish': true,
        'isActive': true,
        'createdAt': '2026-09-21T10:00:00Z',
      };

      final plan = DailyQuizPlanModel.fromJson(buffetJson);
      expect(plan.isOpenBuffet, isTrue);
      expect(plan.displayTitle, 'YDS 2500 Açık Büfe');
      expect(plan.totalWords, 2500);
      expect(plan.completedWordsCount, 5);
      expect(plan.buffetPoolRemainingCount, 2495);
      expect(plan.dailySelectedWordIds, [6, 7, 8]);
      expect(plan.hasDailyBuffetSelection, isTrue);
      expect(plan.progressRatio, 5 / 2500);

      // Serialization
      final json = plan.toJson();
      final fromJson = DailyQuizPlanModel.fromJson(json);
      expect(fromJson.isOpenBuffet, isTrue);
      expect(fromJson.buffetPoolRemainingCount, 2495);
      expect(fromJson.dailySelectedWordIds.length, 3);
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
      final controller = QuizController(
        sampleWords,
        soundService: soundService,
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

    test('Completing last question marks quiz done without clearing questions',
        () async {
      final sampleWords = [
        const WordModel(id: 1, en: 'apple', tr: 'elma'),
        const WordModel(id: 2, en: 'banana', tr: 'muz'),
        const WordModel(id: 3, en: 'orange', tr: 'portakal'),
        const WordModel(id: 4, en: 'grape', tr: 'üzüm'),
      ];

      final soundService = SoundService(enableAudio: false);
      final controller = QuizController(
        sampleWords,
        soundService: soundService,
      );
      controller.generateQuiz(questionCount: 4, englishToTurkish: true);

      while (!controller.state.isQuizCompleted) {
        final currentQ = controller.state.currentQuestion!;
        await controller.selectAnswer(
          currentQ.correctAnswer,
          delay: Duration.zero,
        );
      }

      expect(controller.state.isQuizCompleted, isTrue);
      expect(controller.state.questions, isNotEmpty);
      expect(controller.state.results.length, 4);

      controller.resetToSetup();
      expect(controller.state.isQuizCompleted, isFalse);
      expect(controller.state.questions, isEmpty);
    });

    test('Daily Quiz generation and title format', () {
      final sampleWords = [
        const WordModel(id: 1, en: 'apple', tr: 'elma'),
        const WordModel(id: 2, en: 'banana', tr: 'muz'),
        const WordModel(id: 3, en: 'orange', tr: 'portakal'),
        const WordModel(id: 4, en: 'grape', tr: 'üzüm'),
      ];

      final soundService = SoundService(enableAudio: false);
      final controller = QuizController(
        sampleWords,
        soundService: soundService,
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
      final controller = QuizController(
        sampleWords,
        soundService: soundService,
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

    test('SecureStorageService caches daily plan and QuizController initializes from cache', () async {
      final storage = SecureStorageService();
      final plan = DailyQuizPlanModel(
        id: 'plan_123',
        listName: 'B2',
        dailyCount: 10,
        shuffledWordIds: const [1, 2, 3, 4],
        createdAt: DateTime.now(),
      );

      // Save to cache
      await storage.saveCachedDailyPlan(plan);
      final cached = await storage.getCachedDailyPlan();
      expect(cached, isNotNull);
      expect(cached!.id, 'plan_123');
      expect(cached.listName, 'B2');

      // Controller initializes from cache
      final controller = QuizController(
        const [],
        soundService: SoundService(enableAudio: false),
        storageService: storage,
      );

      // Give async microtask a moment
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.state.dailyPlan, isNotNull);
      expect(controller.state.dailyPlan!.id, 'plan_123');
      expect(controller.state.isPlanLoaded, isTrue);

      // Clean up cache
      await storage.clearCachedDailyPlan();
      final afterClear = await storage.getCachedDailyPlan();
      expect(afterClear, isNull);
    });

    test('Quiz Controller Open Buffet plan creation, word selection, and pool return', () async {
      final sampleWords = List.generate(
        100,
        (i) => WordModel(id: i + 1, en: 'word_${i + 1}', tr: 'kelime_${i + 1}', listName: 'YDS'),
      );

      final controller = QuizController(
        sampleWords,
        soundService: SoundService(enableAudio: false),
      );

      final created = await controller.createPlan(
        title: 'YDS 100 Buffet',
        listName: 'YDS',
        dailyCount: 10,
        englishToTurkish: true,
        planType: PlanType.openBuffet,
      );

      expect(created, isTrue);
      expect(controller.state.dailyPlan, isNotNull);
      expect(controller.state.dailyPlan!.isOpenBuffet, isTrue);
      expect(controller.state.dailyPlan!.totalWords, 100);
      expect(controller.state.dailyPlan!.buffetPoolRemainingCount, 100);

      // Select 10 words for today
      final selectedIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final selectedOk = await controller.selectBuffetWords(selectedIds);
      expect(selectedOk, isTrue);
      expect(controller.state.dailyPlan!.dailySelectedWordIds, selectedIds);

      // Start quiz for today with the buffet selection
      controller.startDailyQuizForToday();
      expect(controller.state.isDailyQuiz, isTrue);
      expect(controller.state.questions.length, 10);
      expect(controller.state.questions.first.word.id, 1);

      // Simulate a completed word returned to pool
      final planWithCompleted = controller.state.dailyPlan!.copyWith(completedWordIds: [1, 2, 3]);
      controller.state = controller.state.copyWith(dailyPlan: planWithCompleted);
      expect(controller.state.dailyPlan!.completedWordsCount, 3);
      expect(controller.state.dailyPlan!.buffetPoolRemainingCount, 97);

      // Return word 2 to pool
      await controller.returnWordToBuffetPool(2);
      expect(controller.state.dailyPlan!.completedWordIds, [1, 3]);
      expect(controller.state.dailyPlan!.buffetPoolRemainingCount, 98);
    });

    test('Quiz Controller Multi-plan switching', () async {
      final sampleWords = List.generate(
        30,
        (i) => WordModel(id: i + 1, en: 'w$i', tr: 'k$i', listName: 'L1'),
      );

      final controller = QuizController(
        sampleWords,
        soundService: SoundService(enableAudio: false),
      );

      // Create Plan 1 (Sequential)
      await controller.createPlan(
        title: 'Plan 1',
        listName: 'L1',
        dailyCount: 5,
        englishToTurkish: true,
        planType: PlanType.sequential,
      );

      // Create Plan 2 (Open Buffet)
      await controller.createPlan(
        title: 'Plan 2',
        listName: 'L1',
        dailyCount: 10,
        englishToTurkish: false,
        planType: PlanType.openBuffet,
      );

      expect(controller.state.allPlans.length, 2);
      expect(controller.state.dailyPlan!.title, 'Plan 2');

      // Switch back to Plan 1
      final plan1 = controller.state.allPlans.firstWhere((p) => p.title == 'Plan 1');
      final switched = await controller.switchActivePlan(plan1.id);
      expect(switched, isTrue);
      expect(controller.state.dailyPlan!.title, 'Plan 1');
      expect(controller.state.dailyPlan!.isOpenBuffet, isFalse);
    });
  });

  group('Study Controller Tests', () {
    test('StudyController matches synonyms from global vocabulary for sublist study', () {
      final studyController = StudyController(TtsService());
      const word1 = WordModel(id: 1, en: 'abundant', tr: 'bol, çok', listName: 'Day 1');
      const word2 = WordModel(id: 2, en: 'plentiful', tr: 'bol; bereketli', listName: 'Day 2');
      const word3 = WordModel(id: 3, en: 'sparse', tr: 'kıt, seyrek', listName: 'Day 3');

      // Studying only Day 1 (word1), but with global vocab [word1, word2, word3]
      studyController.initWithWords([word1], allVocabularyWords: [word1, word2, word3]);

      expect(studyController.state.synonymBadges.isNotEmpty, isTrue);
      expect(studyController.state.synonymBadges.first.word.en, 'plentiful');
      expect(studyController.state.synonymBadges.first.matchedMeaning, 'bol');
    });
  });

  testWidgets('QuizHistoryPage renders compact rows and handles empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizControllerProvider.overrideWith((ref) => QuizController(
                const [],
                soundService: SoundService(enableAudio: false),
              )),
        ],
        child: const MaterialApp(
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

  testWidgets('QuizPage renders 2 top tabs (Quiz Yap & Geçmiş Sonuçlar)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizControllerProvider.overrideWith((ref) => QuizController(
                const [],
                soundService: SoundService(enableAudio: false),
              )),
        ],
        child: const MaterialApp(
          home: QuizPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kelime Testi'), findsOneWidget);
    expect(find.text('Quiz Yap'), findsOneWidget);
    expect(find.text('Geçmiş Sonuçlar'), findsOneWidget);
  });

  testWidgets('DailyPlanPage renders header and plan view', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizControllerProvider.overrideWith((ref) => QuizController(
                const [],
                soundService: SoundService(enableAudio: false),
              )),
        ],
        child: const MaterialApp(
          home: DailyPlanPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Günlük Quiz Planı'), findsOneWidget);
  });

  testWidgets('MainNavigationPage renders 5 tabs including Plan as 4th tab', (WidgetTester tester) async {
    // Bu test go_router StatefulNavigationShell mock'u gerektirdiği için
    // go_router entegrasyonu sonrası ayrı kurulumla güncellenmelidir.
  }, skip: true); // Requires go_router StatefulNavigationShell mock after router migration

  testWidgets('StudySessionPage renders in read-only mode without search bar', (WidgetTester tester) async {
    const testWord = WordModel(id: 1, en: 'solitude', tr: 'yalnızlık', listName: 'B2');

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StudySessionPage(
            words: [testWord],
            listTitle: 'Günün Kelimeleri',
            showSearchBar: false,
            isReadOnly: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('solitude'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  group('SecureStorageService Unit Tests', () {
    test('Token saving, retrieval and clearAll lifecycle', () async {
      final storage = SecureStorageService();
      await storage.clearAll();

      expect(await storage.hasValidToken(), isFalse);

      await storage.saveTokens(
        accessToken: 'mock_jwt_access_token_123',
        refreshToken: 'mock_refresh_token_456',
        email: 'user@wordstation.com',
        userId: 'user_1',
      );

      expect(await storage.hasValidToken(), isTrue);
      expect(await storage.getAccessToken(), 'mock_jwt_access_token_123');
      expect(await storage.getUserEmail(), 'user@wordstation.com');

      await storage.clearAll();
      expect(await storage.hasValidToken(), isFalse);
      expect(await storage.getAccessToken(), isNull);
    });
  });

  testWidgets('WordStationApp smoke test with pump', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WordStationApp(),
      ),
    );

    // Initial frame loads WordStationApp with MaterialApp.router
    expect(find.byType(WordStationApp), findsOneWidget);

    // After auth resolution and router redirect settles
    await tester.pumpAndSettle();
    expect(find.byType(WordStationApp), findsOneWidget);
  });
}


