import 'dart:math';
import 'package:quotes_app/quote.dart';
import 'package:quotes_app/quiz_models.dart';

class QuizService {
  final Random _random = Random();

  List<QuizQuestion> generateQuiz({
    required List<Quote> favoriteQuotes,
    required List<Quote> allQuotes,
    int numberOfQuestions = 20,
  }) {
    if (favoriteQuotes.isEmpty) return [];

    final List<QuizQuestion> questions = [];
    final List<Quote> potentialQuotes = List.from(favoriteQuotes)
      ..shuffle(_random);

    while (questions.length < numberOfQuestions && potentialQuotes.isNotEmpty) {
      final quote = potentialQuotes.removeLast();

      final quizType = _determineQuizType(quote);
      final question = _prepareQuizData(
        quizType,
        quote,
        allQuotes,
        favoriteQuotes,
      );
      if (question != null) {
        questions.add(question);
      }
      if (potentialQuotes.isEmpty && questions.length < numberOfQuestions) {
        // If we run out of unique quotes, allow repeats
        potentialQuotes.addAll(favoriteQuotes..shuffle(_random));
      }
    }
    return questions;
  }

  QuizType _determineQuizType(Quote quote) {
    final availableTypes = _getAvailableQuizTypesForQuote(quote);
    return availableTypes[_random.nextInt(availableTypes.length)];
  }

  List<QuizType> _getAvailableQuizTypesForQuote(Quote quote) {
    final availableTypes = [QuizType.whoSaidThis];
    if (quote.displaySource.isNotEmpty) {
      availableTypes.add(QuizType.whatSource);
    }
    if (quote.authorBirth != null) {
      availableTypes.add(QuizType.authorPeriod);
    }
    if (quote.interpretation != null && quote.interpretation!.isNotEmpty) {
      availableTypes.add(QuizType.matchInterpretation);
    }
    return availableTypes;
  }

  QuizQuestion? generateSingleQuestion({
    required List<Quote> fromQuotes,
    required List<Quote> allQuotes,
    required List<QuizType> allowedTypes,
  }) {
    if (fromQuotes.isEmpty) return null;

    final shuffledQuotes = List<Quote>.from(fromQuotes)..shuffle(_random);

    for (final quote in shuffledQuotes) {
      final availableTypes = _getAvailableQuizTypesForQuote(quote);
      final possibleTypes = availableTypes
          .where((t) => allowedTypes.contains(t))
          .toList();

      if (possibleTypes.isNotEmpty) {
        final quizType = possibleTypes[_random.nextInt(possibleTypes.length)];
        final question = _prepareQuizData(
          quizType,
          quote,
          allQuotes,
          fromQuotes,
        );
        if (question != null && question.options.length > 1) {
          return question;
        }
      }
    }
    return null; // No suitable question found
  }

  QuizQuestion? _prepareQuizData(
    QuizType quizType,
    Quote quote,
    List<Quote> allQuotes,
    List<Quote> favoriteQuotes,
  ) {
    String questionText;
    String correctAnswer;
    List<String> options;
    String? quoteText;

    switch (quizType) {
      case QuizType.whoSaidThis:
        quoteText = quote.text;
        questionText = 'Who said this?';
        correctAnswer = quote.authorInfo;
        final allAuthors = allQuotes.map((q) => q.authorInfo).toSet().toList();
        options = _generateOptions(correctAnswer, allAuthors);
        break;
      case QuizType.whatSource:
        quoteText = quote.text;
        questionText = 'What is the source of this quote?';
        correctAnswer = quote.displaySource;
        final allSources = allQuotes
            .map((q) => q.displaySource)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        options = _generateOptions(correctAnswer, allSources);
        break;
      case QuizType.authorPeriod:
        questionText = 'In what period did ${quote.authorName} live?';
        correctAnswer = '${quote.authorBirth}–${quote.authorDeath}';
        options = _generateAuthorPeriodOptions(correctAnswer);
        break;
      case QuizType.matchInterpretation:
        quoteText = quote.interpretation;
        questionText = 'Which quote does this interpretation refer to?';
        correctAnswer = quote.text;

        final otherInterpretations = favoriteQuotes
            .where((q) => q.id != quote.id && q.text.isNotEmpty)
            .map((q) => q.text)
            .toList();
        options = _generateOptions(correctAnswer, otherInterpretations);
        break;
      default:
        return null;
    }
    if (options.length < 2) return null; // Not enough options to make a quiz

    return QuizQuestion(
      quote: quote,
      quizType: quizType,
      questionText: questionText,
      options: options,
      correctAnswer: correctAnswer,
      quoteText: quoteText,
    );
  }

  List<String> _generateOptions(String correctAnswer, List<String> allItems) {
    final options = <String>{correctAnswer};
    allItems.shuffle(_random);
    for (final item in allItems) {
      if (item != correctAnswer) {
        options.add(item);
        if (options.length >= 4) break;
      }
    }
    return options.toList()..shuffle(_random);
  }

  List<String> _generateAuthorPeriodOptions(String correctPeriod) {
    final options = <String>{correctPeriod};
    final correctYear = int.parse(correctPeriod.split('–')[0]);
    while (options.length < 4) {
      final randomOffset = _random.nextInt(100) - 50;
      final startYear = correctYear + randomOffset;
      final endYear = startYear + (_random.nextInt(40) + 40);
      final period = '$startYear–$endYear';
      if (period != correctPeriod) options.add(period);
    }
    return options.toList()..shuffle(_random);
  }
}
