import 'package:flutter/material.dart';
import 'package:quotes_app/quiz_models.dart';
import 'package:quotes_app/quiz_service.dart';
import 'package:quotes_app/services/time_provider.dart';
import 'package:quotes_app/quote.dart';
import 'srs_service.dart';

// TODO: TimeProvider refactor - DateTime.now() calls replaced with timeProvider.now()
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

class QuizPage extends StatefulWidget {
  final List<Quote> favoriteQuotes;
  final List<Quote> allQuotes;
  final Map<String, int> viewCounts;

  const QuizPage({
    super.key,
    required this.favoriteQuotes,
    required this.allQuotes,
    required this.viewCounts,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late final QuizService _quizService;
  final SRSService _srsService = SRSService();

  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    final sessionSeed = timeProvider.now().millisecondsSinceEpoch;
    _quizService = QuizService(sessionSeed: sessionSeed);
    _startQuiz();
  }

  void _startQuiz() {
    setState(() {
      _questions = _quizService.generateQuiz(
        favoriteQuotes: widget.favoriteQuotes,
        allQuotes: widget.allQuotes,
        viewCounts: widget.viewCounts,
      );
      _currentQuestionIndex = 0;
      _score = 0;
      _answered = false;
      _selectedAnswer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isFinished = _currentQuestionIndex >= _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Comprehensive Quiz',
          style: TextStyle(
            fontFamily: 'Georgia',
            color: Theme.of(context).primaryColor,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _questions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You need to favorite some quotes to start a quiz!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        color: Theme.of(context).primaryColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : (isFinished ? _buildResultsUI() : _buildQuizUI()),
    );
  }

  Widget _buildResultsUI() {
    final double percentage = _questions.isNotEmpty
        ? (_score / _questions.length) * 100
        : 0;
    return Center(
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Quiz Complete!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your Score',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Georgia',
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
              ),
              Text(
                '$_score / ${_questions.length}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Georgia',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                  minimumSize: const Size(200, 50),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Georgia',
                  ),
                ),
                onPressed: _startQuiz,
                child: const Text('Retake Quiz'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Back to Learn Hub',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
            ],
          ),
          if (percentage > 80)
            Align(
              alignment: Alignment.center,
              child: Lottie.asset('assets/confetti.json', repeat: false),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizUI() {
    final question = _questions[_currentQuestionIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Progress Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surface.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}  |  Score: $_score',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),

        // Quote Text
        if (question.quoteText != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '"${question.quoteText}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

        // Question
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
              color: Theme.of(context).primaryColor.withOpacity(0.9),
            ),
          ),
        ),

        // Options
        Expanded(
          child: ListView.builder(
            itemCount: question.options.length,
            itemBuilder: (context, index) {
              final option = question.options[index];
              Color? tileColor;
              IconData? icon;
              if (_answered) {
                if (option == question.correctAnswer) {
                  tileColor = Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2);
                  icon = Icons.check_circle;
                } else if (option == _selectedAnswer) {
                  tileColor = Theme.of(
                    context,
                  ).colorScheme.error.withOpacity(0.2);
                  icon = Icons.cancel;
                }
              }
              return Card(
                elevation: _answered ? 0 : 1,
                margin: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 16.0,
                ),
                color: tileColor ?? (isDark ? Colors.grey[850] : Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _answered && option == question.correctAnswer
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  trailing: icon != null
                      ? Icon(
                          icon,
                          color: option == question.correctAnswer
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
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
                backgroundColor: Theme.of(context).colorScheme.onSurface,
                foregroundColor: Theme.of(context).colorScheme.surface,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _nextQuestion,
              child: Text(
                _currentQuestionIndex < _questions.length - 1
                    ? 'Next Question'
                    : 'Finish Quiz',
                style: const TextStyle(fontSize: 16, fontFamily: 'Georgia'),
              ),
            ),
          ),
      ],
    );
  }

  void _handleAnswer(String answer) {
    if (_answered) return;

    final question = _questions[_currentQuestionIndex];
    final isCorrect = answer == question.correctAnswer;

    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (isCorrect) {
        _score++;
      }
      _srsService.grade(
        question.quote.id,
        correct: isCorrect,
        today: timeProvider.now(),
      );
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _answered = false;
        _selectedAnswer = null;
      } else {
        // Show results page
        setState(() {
          // A bit of a hack to signal the UI to switch
          _currentQuestionIndex++;
          if (_currentQuestionIndex >= _questions.length) {
            _saveQuizResult();
          }
        });
      }
    });
  }

  Future<void> _saveQuizResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'quizzesCompleted',
      (prefs.getInt('quizzesCompleted') ?? 0) + 1,
    );
    await prefs.setInt(
      'totalCorrectAnswers',
      (prefs.getInt('totalCorrectAnswers') ?? 0) + _score,
    );
    await prefs.setInt(
      'totalQuestionsAnswered',
      (prefs.getInt('totalQuestionsAnswered') ?? 0) + _questions.length,
    );
  }
}
