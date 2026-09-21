import 'dart:convert';
import 'quiz_history_model.dart';

class DailyPlanDayModel {
  final int id;
  final int dailyQuizPlanId;
  final int dayNumber;
  final DateTime completedAt;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int score;
  final int maxScore;
  final List<QuizQuestionResult> results;

  const DailyPlanDayModel({
    required this.id,
    required this.dailyQuizPlanId,
    required this.dayNumber,
    required this.completedAt,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.score,
    required this.maxScore,
    required this.results,
  });

  int get percentage =>
      maxScore > 0 ? ((score / maxScore) * 100).round() : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dailyQuizPlanId': dailyQuizPlanId,
        'dayNumber': dayNumber,
        'completedAt': completedAt.toIso8601String(),
        'totalQuestions': totalQuestions,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'score': score,
        'maxScore': maxScore,
        'results': results.map((r) => r.toJson()).toList(),
      };

  factory DailyPlanDayModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['Id'] ?? 0;
    final planId = json['dailyQuizPlanId'] ?? json['DailyQuizPlanId'] ?? 0;
    final dayNum = json['dayNumber'] ?? json['DayNumber'] ?? 1;

    final rawDate = json['completedAt'] ?? json['CompletedAt'];
    DateTime parsedDate;
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawResults = json['results'] ?? json['Results'];
    List<QuizQuestionResult> parsedResults = [];

    if (rawResults is List) {
      parsedResults = rawResults
          .map((r) => QuizQuestionResult.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } else {
      final jsonStr = (json['resultsJson'] ?? json['ResultsJson'] ?? '').toString();
      if (jsonStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is List) {
            parsedResults = decoded
                .map((r) => QuizQuestionResult.fromJson(Map<String, dynamic>.from(r as Map)))
                .toList();
          }
        } catch (_) {}
      }
    }

    return DailyPlanDayModel(
      id: (rawId as num).toInt(),
      dailyQuizPlanId: (planId as num).toInt(),
      dayNumber: (dayNum as num).toInt(),
      completedAt: parsedDate,
      totalQuestions: (json['totalQuestions'] ?? json['TotalQuestions'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] ?? json['CorrectCount'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrongCount'] ?? json['WrongCount'] as num?)?.toInt() ?? 0,
      score: (json['score'] ?? json['Score'] as num?)?.toInt() ?? 0,
      maxScore: (json['maxScore'] ?? json['MaxScore'] as num?)?.toInt() ?? 0,
      results: parsedResults,
    );
  }
}
