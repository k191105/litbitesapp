import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quotes_app/theme/lb_theme_extension.dart';
import '../quote.dart';

class BottomActionBar extends StatelessWidget {
  final Quote currentQuote;
  final List<Quote> favoriteQuotes;
  final Map<String, int> likeCounts;
  final VoidCallback onShare;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onToggleFavorite;
  final void Function(BuildContext) onShowDetails;

  const BottomActionBar({
    super.key,
    required this.currentQuote,
    required this.favoriteQuotes,
    required this.likeCounts,
    required this.onShare,
    required this.onNext,
    required this.onPrevious,
    required this.onToggleFavorite,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final lbTheme = Theme.of(context).extension<LBTheme>()!;

    return Container(
      width: double.infinity,
      height: 100.0,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(width: 1, color: lbTheme.controlBorder)),
        color: lbTheme.controlSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 25.0, right: 25.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              iconSize: 24.0,
              color: lbTheme.controlOnSurface,
              onPressed: () {
                HapticFeedback.selectionClick();
                onShare();
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward_outlined),
              iconSize: 24.0,
              color: lbTheme.controlOnSurface,
              onPressed: () {
                HapticFeedback.selectionClick();
                onNext();
              },
            ),
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    favoriteQuotes.contains(currentQuote)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: favoriteQuotes.contains(currentQuote)
                        ? Colors.red
                        : lbTheme.controlOnSurface,
                  ),
                  if ((likeCounts[currentQuote.id] ?? 0) > 1)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'x${likeCounts[currentQuote.id]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              iconSize: 24.0,
              onPressed: () {
                HapticFeedback.lightImpact();
                onToggleFavorite();
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_upward_outlined),
              iconSize: 24.0,
              color: lbTheme.controlOnSurface,
              onPressed: () {
                HapticFeedback.selectionClick();
                onPrevious();
              },
            ),
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.sell_outlined),
                  iconSize: 24.0,
                  color: lbTheme.controlOnSurface,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onShowDetails(context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
