import 'package:flutter/material.dart';
import '../quote.dart';
import '../utils/font_size_helpers.dart';

class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onDoubleTap;
  final VoidCallback onReadMore;
  final Animation<double> heartAnimation;

  const QuoteCard({
    super.key,
    required this.quote,
    required this.onDoubleTap,
    required this.onReadMore,
    required this.heartAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: double.infinity,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 32.0,
                        bottom: 10.0,
                        top: 32.0,
                        right: 32.0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          quote.text,
                          style: TextStyle(
                            fontSize: getFontSize(quote.text),
                            fontWeight: FontWeight.w500,
                            fontFamily: "EBGaramond",
                            color: Theme.of(context).primaryColor,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 32.0,
                        right: 32.0,
                        top: 10.0,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '— ${quote.authorInfo}',
                          style: TextStyle(
                            fontSize: getSourceFontSize(quote.authorInfo),
                            fontWeight: FontWeight.w300,
                            color: const Color.fromARGB(255, 166, 165, 165),
                            fontFamily: "EBGaramond",
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                    if (quote.displaySource.isNotEmpty) ...[
                      const SizedBox(height: 8.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 32.0, right: 32.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            quote.displaySource,
                            style: TextStyle(
                              fontSize:
                                  getSourceFontSize(quote.displaySource) - 2,
                              fontWeight: FontWeight.w300,
                              color: const Color.fromARGB(255, 140, 140, 140),
                              fontFamily: "EBGaramond",
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: onReadMore,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        side: BorderSide(
                          width: 0.5,
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12.0,
                        ),
                      ),
                      child: Text(
                        'Read more »',
                        style: TextStyle(
                          fontFamily: "EBGaramond",
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: heartAnimation,
            child: ScaleTransition(
              scale: heartAnimation,
              child: Icon(
                Icons.favorite,
                size: 120,
                color: Colors.red.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
