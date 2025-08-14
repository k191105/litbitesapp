import 'package:flutter/material.dart';
import 'quote.dart';

class FlashcardsPage extends StatefulWidget {
  final List<Quote> favoriteQuotes;

  const FlashcardsPage({super.key, required this.favoriteQuotes});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  int _currentIndex = 0;
  bool _isFlipped = false;

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard() {
    if (widget.favoriteQuotes.length > 1) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.favoriteQuotes.length;
        _isFlipped = false;
      });
    }
  }

  void _previousCard() {
    if (widget.favoriteQuotes.length > 1) {
      setState(() {
        _currentIndex =
            (_currentIndex - 1 + widget.favoriteQuotes.length) %
            widget.favoriteQuotes.length;
        _isFlipped = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Flashcards',
          style: TextStyle(fontFamily: 'Georgia', color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: widget.favoriteQuotes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Add quotes to your favorites to use flashcards.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _flipCard,
                  child: Card(
                    margin: const EdgeInsets.all(24.0),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.5,
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          firstChild: _buildCardFront(
                            widget.favoriteQuotes[_currentIndex],
                          ),
                          secondChild: _buildCardBack(
                            widget.favoriteQuotes[_currentIndex],
                          ),
                          crossFadeState: _isFlipped
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  'Tap card to flip',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: _previousCard,
                      iconSize: 32,
                      color: textColor,
                    ),
                    Text(
                      '${_currentIndex + 1} / ${widget.favoriteQuotes.length}',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Georgia',
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: _nextCard,
                      iconSize: 32,
                      color: textColor,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildCardFront(Quote quote) {
    return SingleChildScrollView(
      child: Text(
        quote.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontFamily: 'Georgia',
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCardBack(Quote quote) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '— ${quote.authorInfo}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Georgia',
              fontWeight: FontWeight.bold,
            ),
          ),
          if (quote.displaySource.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              quote.displaySource,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Georgia',
                fontStyle: FontStyle.italic,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
