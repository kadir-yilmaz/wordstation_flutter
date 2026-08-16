import '../../words/models/word_model.dart';

class QuizQuestion {
  final WordModel word;
  final String questionText;
  final String correctAnswer;
  final List<String> options;
  final bool isEnglishToTurkish;

  const QuizQuestion({
    required this.word,
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    this.isEnglishToTurkish = true,
  });
}
