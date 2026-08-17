import 'dart:convert';
import '../../words/models/word_model.dart';

class QuizQuestionResult {
  final WordModel word;
  final String questionText;
  final String correctAnswer;
  final String selectedAnswer;
  final bool isCorrect;

  const QuizQuestionResult({
    required this.word,
    required this.questionText,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() => {
        'word': word.toJson(),
        'questionText': questionText,
        'correctAnswer': correctAnswer,
        'selectedAnswer': selectedAnswer,
        'isCorrect': isCorrect,
      };

  factory QuizQuestionResult.fromJson(Map<String, dynamic> json) {
    final rawWord = json['word'] ?? json['Word'];
    final wordModel = rawWord != null
        ? WordModel.fromJson(Map<String, dynamic>.from(rawWord as Map))
        : WordModel(
            id: 0,
            en: json['questionText']?.toString() ?? '',
            tr: json['correctAnswer']?.toString() ?? '',
          );

    return QuizQuestionResult(
      word: wordModel,
      questionText: (json['questionText'] ?? json['QuestionText'] ?? '').toString(),
      correctAnswer: (json['correctAnswer'] ?? json['CorrectAnswer'] ?? '').toString(),
      selectedAnswer: (json['selectedAnswer'] ?? json['SelectedAnswer'] ?? '').toString(),
      isCorrect: json['isCorrect'] ?? json['IsCorrect'] ?? false,
    );
  }
}

class QuizHistoryModel {
  final String id;
  final DateTime date;
  final String title;
  final int score;
  final int maxScore;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final bool isDailyQuiz;
  final List<QuizQuestionResult> results;

  const QuizHistoryModel({
    required this.id,
    required this.date,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    this.isDailyQuiz = false,
    required this.results,
  });

  int get percentage =>
      maxScore > 0 ? ((score / maxScore) * 100).round() : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'score': score,
        'maxScore': maxScore,
        'totalQuestions': totalQuestions,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'isDailyQuiz': isDailyQuiz,
        'results': results.map((r) => r.toJson()).toList(),
      };

  factory QuizHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['Id'] ?? '';
    final rawDate = json['date'] ?? json['Date'];
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
    } else if (json['resultsJson'] is String && (json['resultsJson'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(json['resultsJson'] as String);
        if (decoded is List) {
          parsedResults = decoded
              .map((r) => QuizQuestionResult.fromJson(Map<String, dynamic>.from(r as Map)))
              .toList();
        }
      } catch (_) {}
    } else if (json['ResultsJson'] is String && (json['ResultsJson'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(json['ResultsJson'] as String);
        if (decoded is List) {
          parsedResults = decoded
              .map((r) => QuizQuestionResult.fromJson(Map<String, dynamic>.from(r as Map)))
              .toList();
        }
      } catch (_) {}
    }

    return QuizHistoryModel(
      id: rawId.toString(),
      date: parsedDate,
      title: (json['title'] ?? json['Title'] ?? 'Genel Test').toString(),
      score: (json['score'] ?? json['Score'] as num?)?.toInt() ?? 0,
      maxScore: (json['maxScore'] ?? json['MaxScore'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] ?? json['TotalQuestions'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] ?? json['CorrectCount'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrongCount'] ?? json['WrongCount'] as num?)?.toInt() ?? 0,
      isDailyQuiz: (json['isDailyQuiz'] ?? json['IsDailyQuiz']) == true,
      results: parsedResults,
    );
  }
}
