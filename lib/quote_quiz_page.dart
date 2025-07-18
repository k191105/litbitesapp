import 'package:flutter/material.dart';
import 'package:quotes_app/quiz_models.dart';
import 'package:quotes_app/quiz_service.dart';
import 'package:quotes_app/srs_service.dart';
import 'quote.dart';

class QuoteQuizPage extends StatefulWidget {
  final List<Quote> favoriteQuotes;
  final List<Quote> allQuotes;
  final bool isDarkMode;

  const QuoteQuizPage({
    super.key,
    required this.favoriteQuotes,
    required this.allQuotes,
    required this.isDarkMode,
  });

  @override
  State<QuoteQuizPage> createState() => _QuoteQuizPageState();
}

class _QuoteQuizPageState extends State<QuoteQuizPage> {
  final QuizService _quizService = QuizService();
  final SRSService _srsService = SRSService();

  QuizQuestion? _currentQuestion;
  bool _answered = false;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  Future<void> _generateQuestion() async {
    final learningData = await _srsService.getLearningData();
    final now = DateTime.now();

    final dueQuotes = widget.favoriteQuotes.where((quote) {
      final data = learningData[quote.id];
      if (data == null) return true;
      return now.difference(data.lastReviewed).inDays >= data.interval;
    }).toList();

    setState(() {
      _currentQuestion = _quizService.generateSingleQuestion(
        fromQuotes: dueQuotes.isNotEmpty ? dueQuotes : widget.favoriteQuotes,
        allQuotes: widget.allQuotes,
        allowedTypes: [QuizType.whoSaidThis, QuizType.whatSource],
      );
      _answered = false;
      _selectedAnswer = null;
    });
  }

  void _handleAnswer(String answer) {
    if (_answered) return;
    final isCorrect = answer == _currentQuestion!.correctAnswer;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _srsService.updateQuote(_currentQuestion!.quote.id, isCorrect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isDarkMode
        ? Colors.black
        : const Color.fromARGB(255, 240, 234, 225);
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Quote Quizzes',
          style: TextStyle(fontFamily: 'Georgia', color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          TextButton(
            onPressed: _generateQuestion,
            child: Text(
              'Skip',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ),
        ],
      ),
      body: _currentQuestion == null
          ? _buildEmptyState(textColor)
          : _buildMultipleChoiceUI(textColor),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Text(
          widget.favoriteQuotes.isEmpty
              ? 'Add quotes to your favorites to start a quiz.'
              : 'Could not generate a question. Try adding more diverse quotes to your favorites!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceUI(Color textColor) {
    final question = _currentQuestion!;
    final isCorrect = _selectedAnswer == question.correctAnswer;

    return Column(
      children: [
        if (question.quoteText != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '"${question.quoteText!}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                color: textColor,
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: question.quoteText == null ? 24.0 : 16.0,
          ),
          child: Text(
            question.questionText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Georgia',
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.9),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: question.options.length,
            itemBuilder: (context, index) {
              final option = question.options[index];
              Color? tileColor;
              IconData? icon;

              if (_answered) {
                if (option == question.correctAnswer) {
                  tileColor = Colors.green.withOpacity(0.2);
                  icon = Icons.check_circle;
                } else if (option == _selectedAnswer) {
                  tileColor = Colors.red.withOpacity(0.2);
                  icon = Icons.cancel;
                }
              }

              return Card(
                elevation: _answered ? 0 : 1,
                margin: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 16.0,
                ),
                color:
                    tileColor ??
                    (widget.isDarkMode ? Colors.grey[850] : Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _answered && option == question.correctAnswer
                        ? Colors.green
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    option,
                    style: TextStyle(fontFamily: 'Georgia', color: textColor),
                  ),
                  trailing: icon != null
                      ? Icon(
                          icon,
                          color: option == question.correctAnswer
                              ? Colors.green
                              : Colors.red,
                        )
                      : null,
                  onTap: () => _handleAnswer(option),
                ),
              );
            },
          ),
        ),
        if (_answered)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isDarkMode
                    ? Colors.white
                    : Colors.black,
                foregroundColor: widget.isDarkMode
                    ? Colors.black
                    : Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _generateQuestion,
              child: Text(
                isCorrect ? 'Next' : 'Continue',
                style: const TextStyle(fontSize: 16, fontFamily: 'Georgia'),
              ),
            ),
          ),
      ],
    );
  }
}
