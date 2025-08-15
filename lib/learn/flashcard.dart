import 'package:flutter/material.dart';
import 'package:quotes_app/quote.dart';

class Flashcard extends StatefulWidget {
  final Quote quote;
  final Function(bool) onAnswer;

  const Flashcard({super.key, required this.quote, required this.onAnswer});

  @override
  State<Flashcard> createState() => _FlashcardState();
}

class _FlashcardState extends State<Flashcard> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.quote.text),
        const SizedBox(height: 16),
        if (_showAnswer) ...[
          Text(widget.quote.authorName),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => widget.onAnswer(true),
                child: const Text('I was right'),
              ),
              ElevatedButton(
                onPressed: () => widget.onAnswer(false),
                child: const Text('I was wrong'),
              ),
            ],
          ),
        ] else ...[
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showAnswer = true;
              });
            },
            child: const Text('Show Answer'),
          ),
        ],
      ],
    );
  }
}
