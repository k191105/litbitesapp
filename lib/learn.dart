import 'package:flutter/material.dart';
import 'dart:math';
import 'quote.dart';
import 'srs_service.dart';

enum QuizType { whoSaidThis, whatSource, unscramble, authorPeriod }

class LearnPage extends StatefulWidget {
  final List<Quote> favoriteQuotes;
  final List<Quote> allQuotes;
  final bool isDarkMode;

  const LearnPage({
    super.key,
    required this.favoriteQuotes,
    required this.allQuotes,
    required this.isDarkMode,
  });

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  final Random _random = Random();
  final SRSService _srsService = SRSService();
  Quote? _currentQuote;
  QuizType? _quizType;
  String? _quoteText;
  String _questionText = '';
  List<String> _options = [];
  String _correctAnswer = '';
  String? _selectedAnswer;
  bool _answered = false;

  List<String> _scrambledWords = [];
  List<String> _orderedWords = [];
  bool _showedAnswer = false;

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
      if (data == null) return true; // New quotes are always due
      return now.difference(data.lastReviewed).inDays >= data.interval;
    }).toList();

    setState(() {
      _answered = false;
      _selectedAnswer = null;
      _quoteText = null;
      _questionText = '';
      _showedAnswer = false;

      if (dueQuotes.isNotEmpty) {
        _currentQuote = dueQuotes[_random.nextInt(dueQuotes.length)];
      } else if (widget.favoriteQuotes.isNotEmpty) {
        // Fallback if no quotes are due
        _currentQuote = widget
            .favoriteQuotes[_random.nextInt(widget.favoriteQuotes.length)];
      } else {
        // Should not happen if favorites are required to enter
        Navigator.pop(context);
        return;
      }

      _determineQuizType();
      _prepareQuizData();
    });
  }

  void _determineQuizType() {
    final availableTypes = [QuizType.whoSaidThis];
    if (_currentQuote!.displaySource.isNotEmpty) {
      availableTypes.add(QuizType.whatSource);
    }
    if (_currentQuote!.text.split(' ').length <= 8 &&
        _currentQuote!.text.split(' ').length > 2) {
      availableTypes.add(QuizType.unscramble);
    }
    if (_currentQuote!.authorBirth != null) {
      availableTypes.add(QuizType.authorPeriod);
    }
    _quizType = availableTypes[_random.nextInt(availableTypes.length)];
  }

  void _prepareQuizData() {
    switch (_quizType) {
      case QuizType.whoSaidThis:
        _quoteText = _currentQuote!.text;
        _questionText = 'Who said this?';
        _correctAnswer = _currentQuote!.authorInfo;
        final allAuthors = widget.allQuotes
            .map((q) => q.authorInfo)
            .toSet()
            .toList();
        _options = _generateOptions(_correctAnswer, allAuthors);
        break;
      case QuizType.whatSource:
        _quoteText = _currentQuote!.text;
        _questionText = 'What is the source of this quote?';
        _correctAnswer = _currentQuote!.displaySource;
        final allSources = widget.allQuotes
            .map((q) => q.displaySource)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        _options = _generateOptions(_correctAnswer, allSources);
        break;
      case QuizType.authorPeriod:
        _questionText = 'In what period did ${_currentQuote!.authorName} live?';
        _correctAnswer =
            '${_currentQuote!.authorBirth}–${_currentQuote!.authorDeath}';
        _options = _generateAuthorPeriodOptions(_correctAnswer);
        break;
      case QuizType.unscramble:
        _questionText = 'Unscramble the rest of the quote:';
        final originalWords = _currentQuote!.text.split(' ');
        _orderedWords = originalWords.take(2).toList();
        _scrambledWords = originalWords.skip(2).toList()..shuffle(_random);
        break;
      default:
        break;
    }
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

  void _handleAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _srsService.updateQuote(_currentQuote!.id, answer == _correctAnswer);
    });
  }

  void _onScrambleComplete() {
    final original = _currentQuote!.text;
    final constructed = _orderedWords.join(' ');
    final isCorrect = original == constructed;
    _srsService.updateQuote(_currentQuote!.id, isCorrect);
    setState(() {}); // Trigger rebuild to show buttons
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Learn',
          style: TextStyle(
            fontFamily: 'Georgia',
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: widget.isDarkMode
            ? Colors.black
            : const Color.fromARGB(255, 240, 234, 225),
        elevation: 0,
        iconTheme: IconThemeData(
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
        actions: [
          TextButton(
            onPressed: _generateQuestion,
            child: Text(
              'Skip',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: widget.isDarkMode
          ? Colors.black
          : const Color.fromARGB(255, 240, 234, 225),
      body: _currentQuote == null
          ? const Center(child: CircularProgressIndicator())
          : _quizType == QuizType.unscramble
          ? _buildScrambleUI()
          : _buildMultipleChoiceUI(),
    );
  }

  Widget _buildMultipleChoiceUI() {
    final isCorrect = _selectedAnswer == _correctAnswer;
    return Column(
      children: [
        if (_quoteText != null)
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
              '"$_quoteText"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: _quoteText == null ? 24.0 : 16.0,
          ),
          child: Text(
            _questionText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Georgia',
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.9)
                  : Colors.black.withOpacity(0.9),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _options.length,
            itemBuilder: (context, index) {
              final option = _options[index];
              Color? tileColor;
              IconData? icon;
              if (_answered) {
                if (option == _correctAnswer) {
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
                    color: _answered && option == _correctAnswer
                        ? Colors.green
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  trailing: icon != null
                      ? Icon(
                          icon,
                          color: option == _correctAnswer
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

  Widget _buildScrambleUI() {
    bool isFinished = _scrambledWords.isEmpty;
    bool isCorrect = false;
    if (isFinished) {
      final original = _currentQuote!.text;
      final constructed = _orderedWords.join(' ');
      isCorrect = original == constructed;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _questionText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Georgia',
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        DragTarget<Map<String, dynamic>>(
          onAccept: (data) => _handleWordDrop(data, 'ordered'),
          builder: (context, candidateData, rejectedData) {
            return Container(
              constraints: const BoxConstraints(minHeight: 150),
              width: double.infinity,
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFinished && isCorrect
                      ? Colors.green
                      : (widget.isDarkMode ? Colors.white30 : Colors.black12),
                ),
              ),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _orderedWords.asMap().entries.map((entry) {
                  final isFixed = entry.key < 2;
                  return _buildWordChip(
                    entry.value,
                    isDraggable: !isFixed,
                    data: {
                      'word': entry.value,
                      'index': entry.key,
                      'from': 'ordered',
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        Expanded(
          child: DragTarget<Map<String, dynamic>>(
            onAccept: (data) => _handleWordDrop(data, 'scrambled'),
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _scrambledWords.asMap().entries.map((entry) {
                        return _buildWordChip(
                          entry.value,
                          isDraggable: true,
                          data: {
                            'word': entry.value,
                            'index': entry.key,
                            'from': 'scrambled',
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (isFinished)
          _showedAnswer
              ? _buildNextButton()
              : isCorrect
              ? _buildNextButton()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(child: _buildTryAgainButton()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildShowAnswerButton()),
                  ],
                ),
      ],
    );
  }

  Widget _buildTryAgainButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _scrambledWords.addAll(_orderedWords.skip(2));
            _orderedWords.removeRange(2, _orderedWords.length);
            _scrambledWords.shuffle();
          });
        },
        child: const Text(
          'Try Again',
          style: TextStyle(fontSize: 16, fontFamily: 'Georgia'),
        ),
      ),
    );
  }

  Widget _buildShowAnswerButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 16),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _orderedWords = _currentQuote!.text.split(' ');
            _scrambledWords.clear();
            _showedAnswer = true;
          });
        },
        child: const Text(
          'Show Answer',
          style: TextStyle(fontSize: 16, fontFamily: 'Georgia'),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _generateQuestion,
        child: const Text(
          'Next',
          style: TextStyle(fontSize: 16, fontFamily: 'Georgia'),
        ),
      ),
    );
  }

  void _handleWordDrop(Map<String, dynamic> data, String to) {
    final String word = data['word'];
    final int index = data['index'];
    final String from = data['from'];

    if (from == to) return;

    setState(() {
      if (from == 'scrambled' && to == 'ordered') {
        _orderedWords.add(word);
        _scrambledWords.removeAt(index);
      } else if (from == 'ordered' && to == 'scrambled') {
        _scrambledWords.add(word);
        _orderedWords.removeAt(index);
      }

      if (_scrambledWords.isEmpty) {
        _onScrambleComplete();
      }
    });
  }

  Widget _buildWordChip(
    String word, {
    required bool isDraggable,
    Map<String, dynamic>? data,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDraggable
            ? (widget.isDarkMode ? Colors.grey[800] : Colors.white)
            : (widget.isDarkMode
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDraggable
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Text(
        word,
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black,
          fontFamily: 'Georgia',
          fontSize: 16,
        ),
      ),
    );

    if (!isDraggable) return chip;

    return Draggable<Map<String, dynamic>>(
      data: data!,
      feedback: Material(color: Colors.transparent, child: chip),
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: chip,
    );
  }
}
