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
import 'package:dio/dio.dart';
import 'package:wordstation_flutter/core/network/api_client.dart';
import 'package:wordstation_flutter/features/words/controllers/study_controller.dart';
import 'package:wordstation_flutter/features/words/controllers/word_list_controller.dart';
import 'package:wordstation_flutter/features/words/models/synonym_group_model.dart';
import 'package:wordstation_flutter/features/words/models/word_model.dart';
import 'package:wordstation_flutter/features/words/pages/study_session_page.dart';
import 'package:wordstation_flutter/features/words/pages/words_list_page.dart';
import 'package:wordstation_flutter/features/words/services/word_service.dart';
import 'package:wordstation_flutter/features/navigation/main_navigation_page.dart';
import 'package:go_router/go_router.dart';
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

    test('DailyQuizPlanModel sequential progression and computed properties', () {
      final sequentialJson = {
        'id': 42,
        'listName': 'YDS',
        'dailyCount': 50,
        'shuffledWordIds': List.generate(2500, (i) => i + 1),
        'currentPointer': 200,
        'streakDays': 5,
        'isEnglishToTurkish': true,
        'isActive': true,
        'createdAt': '2026-09-21T10:00:00Z',
      };

      final plan = DailyQuizPlanModel.fromJson(sequentialJson);
      expect(plan.listName, 'YDS');
      expect(plan.totalWords, 2500);
      expect(plan.currentPointer, 200);
      expect(plan.progressRatio, 200 / 2500);

      // Serialization
      final json = plan.toJson();
      final fromJson = DailyQuizPlanModel.fromJson(json);
      expect(fromJson.currentPointer, 200);
      expect(fromJson.totalWords, 2500);
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

    test('Quiz Controller sequential plan creation and daily quiz start', () async {
      final sampleWords = List.generate(
        100,
        (i) => WordModel(id: i + 1, en: 'word_${i + 1}', tr: 'kelime_${i + 1}', listName: 'YDS'),
      );

      final controller = QuizController(
        sampleWords,
        soundService: SoundService(enableAudio: false),
      );

      final created = await controller.createPlan(
        listName: 'YDS',
        dailyCount: 10,
        englishToTurkish: true,
      );

      expect(created, isTrue);
      expect(controller.state.dailyPlan, isNotNull);
      expect(controller.state.dailyPlan!.totalWords, 100);
      expect(controller.state.dailyPlan!.dailyCount, 10);

      // Start quiz for today
      controller.startDailyQuizForToday();
      expect(controller.state.isDailyQuiz, isTrue);
      expect(controller.state.questions.length, 10);
      expect(controller.state.questions.first.word.id, isNotNull);
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
    expect(find.text('HEDEF KELİME LİSTESİ'), findsOneWidget);
  });

  testWidgets('Study session routes render tabbar in MainNavigationShell', (WidgetTester tester) async {
    const testWord = WordModel(id: 1, en: 'solitude', tr: 'yalnızlık', listName: 'B2');

    final testWordsNavKey = GlobalKey<NavigatorState>();
    final testSynonymsNavKey = GlobalKey<NavigatorState>();
    final testQuizNavKey = GlobalKey<NavigatorState>();
    final testPlanNavKey = GlobalKey<NavigatorState>();
    final testProfileNavKey = GlobalKey<NavigatorState>();

    final testRouter = GoRouter(
      initialLocation: '/words',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainNavigationShell(
              navigationShell: navigationShell,
              branchNavKeys: [
                testWordsNavKey,
                testSynonymsNavKey,
                testQuizNavKey,
                testPlanNavKey,
                testProfileNavKey,
              ],
            );
          },
          branches: [
            StatefulShellBranch(
              navigatorKey: testWordsNavKey,
              routes: [
                GoRoute(
                  path: '/words',
                  builder: (context, state) => const Scaffold(body: Text('Words List')),
                  routes: [
                    GoRoute(
                      path: 'study',
                      builder: (context, state) => const StudySessionPage(
                        words: [testWord],
                        listTitle: 'B2',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: testSynonymsNavKey,
              routes: [
                GoRoute(path: '/synonyms', builder: (c, s) => const Scaffold(body: Text('Synonyms List'))),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: testQuizNavKey,
              routes: [
                GoRoute(path: '/quiz', builder: (c, s) => const Scaffold(body: Text('Quiz Page'))),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: testPlanNavKey,
              routes: [
                GoRoute(
                  path: '/plan',
                  builder: (context, state) => const Scaffold(body: Text('Plan Page')),
                  routes: [
                    GoRoute(
                      path: 'study',
                      builder: (context, state) => const StudySessionPage(
                        words: [testWord],
                        listTitle: 'Plan Study',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: testProfileNavKey,
              routes: [
                GoRoute(path: '/profile', builder: (c, s) => const Scaffold(body: Text('Profile Page'))),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: testRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial Words List and tab bar items visible
    expect(find.text('Words List'), findsOneWidget);
    expect(find.text('My Lists'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);

    // Push /words/study
    testRouter.push('/words/study');
    await tester.pumpAndSettle();

    // Verify StudySessionPage is displayed AND tabbar (My Lists, Plan) is visible!
    expect(find.text('solitude'), findsOneWidget);
    expect(find.text('My Lists'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);

    // Pop back to words list
    testRouter.pop();
    await tester.pumpAndSettle();
    expect(find.text('Words List'), findsOneWidget);
    expect(find.text('My Lists'), findsOneWidget);
  });

  testWidgets('MainNavigationShell tab history navigates back through visited tabs', (WidgetTester tester) async {
    final navKey0 = GlobalKey<NavigatorState>();
    final navKey1 = GlobalKey<NavigatorState>();
    final navKey2 = GlobalKey<NavigatorState>();
    final navKey3 = GlobalKey<NavigatorState>();
    final navKey4 = GlobalKey<NavigatorState>();

    final testRouter = GoRouter(
      initialLocation: '/words',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainNavigationShell(
              navigationShell: navigationShell,
              branchNavKeys: [navKey0, navKey1, navKey2, navKey3, navKey4],
            );
          },
          branches: [
            StatefulShellBranch(
              navigatorKey: navKey0,
              routes: [
                GoRoute(path: '/words', builder: (c, s) => const Scaffold(body: Text('Words Tab'))),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: navKey1,
              routes: [
                GoRoute(path: '/synonyms', builder: (c, s) => const Scaffold(body: Text('Synonyms Tab'))),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: navKey2,
              routes: [
                GoRoute(path: '/quiz', builder: (c, s) => const Scaffold(body: Text('Quiz Tab'))),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: navKey3,
              routes: [
                GoRoute(path: '/plan', builder: (c, s) => const Scaffold(body: Text('Plan Tab'))),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: navKey4,
              routes: [
                GoRoute(path: '/profile', builder: (c, s) => const Scaffold(body: Text('Profile Tab'))),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: testRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Words Tab'), findsOneWidget);

    // Tap Plan tab (index 3 in UI)
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Plan Tab'), findsOneWidget);

    // Simulate system back button
    final popHandled = await tester.binding.handlePopRoute();
    expect(popHandled, isTrue);
    await tester.pumpAndSettle();

    // Verify it returned to Words Tab (previous tab in history)!
    expect(find.text('Words Tab'), findsOneWidget);
  });

  testWidgets('DailyPlanPage header back button returns from sub-screen to plans list', (WidgetTester tester) async {
    final samplePlan = DailyQuizPlanModel(
      id: 'plan-test',
      listName: 'YDS',
      dailyCount: 10,
      shuffledWordIds: List.generate(50, (i) => i + 1),
      createdAt: DateTime(2026, 1, 1),
    );

    final mockController = QuizController(
      const [],
      soundService: SoundService(enableAudio: false),
    );
    mockController.state = mockController.state.copyWith(
      isPlanLoaded: true,
      dailyPlan: samplePlan,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizControllerProvider.overrideWith((ref) => mockController),
        ],
        child: const MaterialApp(
          home: DailyPlanPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Günlük Quiz Planı'), findsOneWidget);

    // Tap active plan card to open history
    await tester.tap(find.text('0 Günlük Seri'));
    await tester.pumpAndSettle();

    expect(find.text('Geçmiş Quizler'), findsOneWidget);

    // Tap back button in header
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    // Should return to Daily Plan dashboard
    expect(find.text('Günlük Quiz Planı'), findsOneWidget);
  });

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

    test('Custom list order persistence and lifecycle', () async {
      final storage = SecureStorageService();
      await storage.clearCustomListOrder();

      expect(await storage.getCustomListOrder(), isEmpty);

      await storage.saveCustomListOrder(['YDS', 'B2', 'General']);
      expect(await storage.getCustomListOrder(), ['YDS', 'B2', 'General']);

      await storage.clearCustomListOrder();
      expect(await storage.getCustomListOrder(), isEmpty);
    });
  });

  group('Daily Plan Overview & Cards Unit and Widget Tests', () {
    test('DailyQuizPlanModel totalWords, and properties format correctly', () {
      final plan1 = DailyQuizPlanModel(
        id: 'plan-1',
        listName: 'Phrasal Verbs',
        dailyCount: 10,
        shuffledWordIds: List.generate(185, (i) => i + 1),
        createdAt: DateTime(2026, 1, 1),
      );

      final plan2 = DailyQuizPlanModel(
        id: 'plan-2',
        listName: 'YDS',
        dailyCount: 20,
        shuffledWordIds: List.generate(2488, (i) => i + 1),
        createdAt: DateTime(2026, 1, 1),
      );

      expect(plan1.listName, 'Phrasal Verbs');
      expect(plan1.totalWords, 185);

      expect(plan2.listName, 'YDS');
      expect(plan2.totalWords, 2488);
    });

    testWidgets('DailyPlanPage renders initial frame with Günlük Quiz Planı header', (WidgetTester tester) async {
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
      await tester.pump();

      expect(find.text('Günlük Quiz Planı'), findsOneWidget);
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

  group('Word List Custom Ordering and UI Tests', () {
    test('applyListOrder sorts alphabetically if saved order is empty', () {
      final raw = ['General', 'YDS', 'B2', 'A1'];
      final sorted = WordListController.applyListOrder(raw, []);
      expect(sorted, ['A1', 'B2', 'General', 'YDS']);
    });

    test('applyListOrder prioritizes saved order and appends remaining lists alphabetically', () {
      final raw = ['General', 'YDS', 'B2', 'A1'];
      final savedOrder = ['YDS', 'B2'];
      final sorted = WordListController.applyListOrder(raw, savedOrder);
      // YDS is first, B2 is second, remaining (A1, General) are sorted alphabetically
      expect(sorted, ['YDS', 'B2', 'A1', 'General']);
    });

    test('WordListController reorderLists updates state and moves YDS to top', () async {
      final storage = SecureStorageService();
      await storage.clearCustomListOrder();

      final mockWords = [
        const WordModel(id: 1, en: 'apple', tr: 'elma', listName: 'General'),
        const WordModel(id: 2, en: 'ubiquitous', tr: 'yaygın', listName: 'YDS'),
        const WordModel(id: 3, en: 'elaborate', tr: 'ayrıntılı', listName: 'B2'),
      ];
      final wordService = MockWordService(mockWords);
      final controller = WordListController(wordService, storageService: storage);

      // Wait for loadInitialData
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.state.listNames, ['B2', 'General', 'YDS']);

      // Reorder: Move 'YDS' (index 2) to index 0
      await controller.reorderLists(2, 0);

      expect(controller.state.listNames, ['YDS', 'B2', 'General']);
      expect(controller.state.listNames.first, 'YDS');

      // Verify persisted in storage
      final saved = await storage.getCustomListOrder();
      expect(saved, ['YDS', 'B2', 'General']);
    });

    testWidgets('WordsListPage renders ReorderableListView, drag handles, and sort menu', (WidgetTester tester) async {
      final mockWords = [
        const WordModel(id: 1, en: 'apple', tr: 'elma', listName: 'General'),
        const WordModel(id: 2, en: 'ubiquitous', tr: 'yaygın', listName: 'YDS'),
      ];
      final wordService = MockWordService(mockWords);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wordListControllerProvider.overrideWith(
              (ref) => WordListController(wordService, storageService: SecureStorageService()),
            ),
          ],
          child: const MaterialApp(
            home: WordsListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Lists'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);
    });
  });
}

class MockWordService extends WordService {
  final List<WordModel> mockWords;
  MockWordService(this.mockWords)
      : super(ApiClient(Dio()), SecureStorageService());

  @override
  Future<List<WordModel>> getWords({String? listName}) async {
    if (listName != null) {
      return mockWords.where((w) => w.listName == listName).toList();
    }
    return mockWords;
  }
}


