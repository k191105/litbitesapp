import 'package:flutter/material.dart';
import 'package:quotes_app/srs_service.dart';
import 'package:quotes_app/services/time_provider.dart';
import 'package:quotes_app/quote.dart';
import 'package:quotes_app/learn/flashcard.dart';
import 'package:quotes_app/services/analytics.dart';
import 'package:quotes_app/utils/feature_gate.dart';

// TODO: TimeProvider refactor - DateTime.now() calls replaced with timeProvider.now()

class SrsSessionScreen extends StatefulWidget {
  final List<Quote> allQuotes;
  final List<Quote> favoriteQuotes;

  const SrsSessionScreen({
    super.key,
    required this.allQuotes,
    required this.favoriteQuotes,
  });

  @override
  State<SrsSessionScreen> createState() => _SrsSessionScreenState();
}

class _SrsSessionScreenState extends State<SrsSessionScreen> {
  final SRSService _srsService = SRSService();
  List<String> _dueQuoteIds = [];
  int _currentIndex = 0;
  int _reviewsToday = 0;
  bool _capReached = false;

  @override
  void initState() {
    super.initState();
    Analytics.instance.logEvent(Analytics.learnSrsOpened);
    _loadDueQuotes();
  }

  Future<void> _loadDueQuotes() async {
    final dueQuoteIds = await _srsService.loadDue(timeProvider.now());
    final canReviewMore = await _srsService.canReviewMore(timeProvider.now());
    setState(() {
      _dueQuoteIds = dueQuoteIds;
      _capReached = !canReviewMore;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spaced Repetition (${_dueQuoteIds.length} due)'),
      ),
      body: _capReached
          ? _buildCapReachedNudge()
          : (_dueQuoteIds.isEmpty ? _buildEmptyState() : _buildSession()),
    );
  }

  Widget _buildCapReachedNudge() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('You\'ve reached your daily review limit!'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              openPaywall(context: context, contextKey: 'srs_unlimited');
            },
            child: const Text('See options'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No reviews due today!'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final favoriteQuoteIds = widget.favoriteQuotes
                  .map((q) => q.id)
                  .toSet();
              _srsService.addMany(favoriteQuoteIds);
              Analytics.instance.logEvent(Analytics.learnAddToSrs, {
                'count': favoriteQuoteIds.length,
                'source': 'favorites',
              });
              _loadDueQuotes();
            },
            child: const Text('Add from Favorites'),
          ),
        ],
      ),
    );
  }

  Widget _buildSession() {
    final quote = widget.allQuotes.firstWhere(
      (q) => q.id == _dueQuoteIds[_currentIndex],
    );
    return Flashcard(
      quote: quote,
      onAnswer: (correct) {
        _srsService.grade(
          quote.id,
          correct: correct,
          today: timeProvider.now(),
        );
        setState(() {
          _reviewsToday++;
        });
        Analytics.instance.logEvent(Analytics.learnSrsGraded, {
          'correct': correct,
        });
        if (_currentIndex < _dueQuoteIds.length - 1) {
          setState(() {
            _currentIndex++;
          });
        } else {
          Analytics.instance.logEvent(Analytics.learnSrsFinished, {
            'reviewed': _dueQuoteIds.length,
            'remaining': 0,
          });
          _loadDueQuotes();
        }
      },
    );
  }
}
