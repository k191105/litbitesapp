import 'package:flutter/material.dart';
import '../quote.dart';

class DetailsPopupContent extends StatelessWidget {
  final Quote quote;
  final Widget Function(String, {void Function(String)? onTap}) buildTagChip;
  final Widget Function(String, {void Function(String)? onTap}) buildAuthorChip;
  final void Function(String) onTagToggled;
  final void Function(String) onAuthorToggled;

  const DetailsPopupContent({
    super.key,
    required this.quote,
    required this.buildTagChip,
    required this.buildAuthorChip,
    required this.onTagToggled,
    required this.onAuthorToggled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: isDark
              ? const Color.fromARGB(220, 45, 45, 45)
              : const Color.fromARGB(240, 255, 255, 255),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 15,
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tags Column
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Tags',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'EBGaramond',
                        ),
                      ),
                    ),
                    if (quote.tags.isEmpty)
                      const Text(
                        'No tags for this quote.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontFamily: 'EBGaramond',
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: quote.tags.map((tag) {
                          return buildTagChip(
                            tag,
                            onTap: (selectedTag) {
                              Navigator.pop(context);
                              onTagToggled(selectedTag);
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              const VerticalDivider(width: 24),

              // Author Column
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Author',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'EBGaramond',
                        ),
                      ),
                    ),
                    buildAuthorChip(
                      quote.authorName,
                      onTap: (selectedAuthor) {
                        Navigator.pop(context);
                        onAuthorToggled(selectedAuthor);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
