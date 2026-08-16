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

  factory QuizQuestionResult.fromJson(Map<String, dynamic> json) =>
      QuizQuestionResult(
        word: WordModel.fromJson(
            Map<String, dynamic>.from(json['word'] as Map)),
        questionText: json['questionText'] as String? ?? '',
        correctAnswer: json['correctAnswer'] as String? ?? '',
        selectedAnswer: json['selectedAnswer'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
      );
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

  factory QuizHistoryModel.fromJson(Map<String, dynamic> json) =>
      QuizHistoryModel(
        id: json['id'] as String? ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
            : DateTime.now(),
        title: json['title'] as String? ?? 'Genel Test',
        score: json['score'] as int? ?? 0,
        maxScore: json['maxScore'] as int? ?? 0,
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        wrongCount: json['wrongCount'] as int? ?? 0,
        isDailyQuiz: json['isDailyQuiz'] as bool? ?? false,
        results: (json['results'] as List<dynamic>? ?? [])
            .map((r) => QuizQuestionResult.fromJson(
                Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}
