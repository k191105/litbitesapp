import 'package:quotes_app/quote.dart';

enum QuizType { whoSaidThis, whatSource, authorPeriod }

class QuizQuestion {
  final Quote quote;
  final QuizType quizType;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? quoteText;

  QuizQuestion({
    required this.quote,
    required this.quizType,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.quoteText,
  });
}
