import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordstation_flutter/core/constants/api_constants.dart';
import 'package:wordstation_flutter/core/storage/secure_storage_service.dart';
import 'package:wordstation_flutter/features/plan/controllers/plan_controller.dart';
import 'package:wordstation_flutter/features/plan/models/daily_plan_day_model.dart';
import 'package:wordstation_flutter/features/plan/models/daily_quiz_plan_model.dart';
import 'package:wordstation_flutter/features/plan/repositories/plan_repository.dart';
import 'package:wordstation_flutter/features/plan/services/daily_quiz_api_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('DailyQuizPlanModel - Progression & Pointer Math', () {
    test('Zero-repeat pointer math and progression', () {
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
      expect(day3Plan.nextBatchCount, 4); // Remaining 4 words
      expect(day3Plan.remainingWords, 4);
      expect(day3Plan.isPlanFinished, isFalse);

      // Day 3 completed -> All words done
      final finishedPlan = day3Plan.copyWith(currentPointer: 14);
      expect(finishedPlan.isPlanFinished, isTrue);
      expect(finishedPlan.remainingWords, 0);
      expect(finishedPlan.progressPercentage, 100);
    });

    test('Parses backend .NET DTO response format with integer/string ID tolerance', () {
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

    test('Sequential progression math with large word pools (2500 words)', () {
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
      expect(plan.totalDays, 50);
    });
  });

  group('DailyPlanDayModel - Serialization Tests', () {
    test('DailyPlanDayModel serialization and percentage', () {
      final day = DailyPlanDayModel(
        id: 1,
        dailyQuizPlanId: 10,
        dayNumber: 3,
        completedAt: DateTime.now(),
        totalQuestions: 10,
        correctCount: 8,
        wrongCount: 2,
        score: 80,
        maxScore: 100,
        results: const [],
      );

      expect(day.percentage, 80);
      final json = day.toJson();
      expect(json['dayNumber'], 3);
      expect(json['score'], 80);

      final parsed = DailyPlanDayModel.fromJson(json);
      expect(parsed.id, 1);
      expect(parsed.dayNumber, 3);
      expect(parsed.score, 80);
    });

    test('PlanController.deduplicateDays collapses repeated day numbers into single latest entry', () {
      final now = DateTime.now();
      final day1 = DailyPlanDayModel(
        id: 1,
        dailyQuizPlanId: 10,
        dayNumber: 1,
        completedAt: now.subtract(const Duration(days: 1)),
        totalQuestions: 10,
        correctCount: 10,
        wrongCount: 0,
        score: 100,
        maxScore: 100,
        results: const [],
      );

      // Simulating the 174 duplicate day 2 entries created by the build loop
      final duplicateDay2Entries = List.generate(174, (i) => DailyPlanDayModel(
        id: 100 + i,
        dailyQuizPlanId: 10,
        dayNumber: 2,
        completedAt: now.add(Duration(seconds: i)),
        totalQuestions: 10,
        correctCount: 9,
        wrongCount: 1,
        score: 90,
        maxScore: 100,
        results: const [],
      ));

      final allDays = [day1, ...duplicateDay2Entries];
      final deduplicated = PlanController.deduplicateDays(allDays);

      // Should only have 2 distinct days
      expect(deduplicated.length, 2);
      expect(deduplicated.map((d) => d.dayNumber).toSet(), {1, 2});

      // Day 2 should be the latest entry (highest id / latest completedAt)
      final keptDay2 = deduplicated.firstWhere((d) => d.dayNumber == 2);
      expect(keptDay2.id, 100 + 173);
    });
  });

  group('Daily Plan API & Repository Integration', () {
    test('getActivePlan and deletePlan perform HTTP calls properly', () async {
      final storage = SecureStorageService();
      await storage.clearAll();
      await storage.saveTokens(
        accessToken: 'mock_token',
        refreshToken: 'mock_refresh',
        userId: 'usr_plan_test',
        email: 'plan@wordstation.com',
      );

      final mockClient = createMockApiClient((options) {
        if (options.path.contains(ApiConstants.dailyQuiz) && options.method == 'GET') {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'id': 'plan_999',
              'userId': 'usr_plan_test',
              'listName': 'YDS',
              'dailyCount': 20,
              'shuffledWordIds': [1, 2, 3, 4, 5],
              'currentPointer': 0,
              'streakDays': 0,
              'isEnglishToTurkish': true,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
        } else if (options.path.contains(ApiConstants.dailyQuiz) && options.method == 'DELETE') {
          return Response(requestOptions: options, statusCode: 200, data: true);
        }
        return Response(requestOptions: options, statusCode: 404);
      });

      final apiService = DailyQuizApiService(mockClient, storage);
      final repo = PlanRepositoryImpl(apiService: apiService);

      final plan = await repo.getActivePlan();
      expect(plan, isNotNull);
      expect(plan!.id, 'plan_999');
      expect(plan.listName, 'YDS');
      expect(plan.dailyCount, 20);

      final deleted = await repo.deletePlan();
      expect(deleted, isTrue);
    });
  });
}
