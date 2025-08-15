import 'package:flutter/material.dart';
import '../quote.dart';
import '../services/entitlements_service.dart';
import '../utils/feature_gate.dart';

class DetailsPopupContent extends StatefulWidget {
  final Quote quote;
  final Widget Function(String, {void Function(String)? onTap}) buildTagChip;
  final Widget Function(String, {void Function(String)? onTap}) buildAuthorChip;
  final void Function(String) onTagToggled;
  final void Function(String) onAuthorToggled;
  final VoidCallback? onRequestClose;

  const DetailsPopupContent({
    super.key,
    required this.quote,
    required this.buildTagChip,
    required this.buildAuthorChip,
    required this.onTagToggled,
    required this.onAuthorToggled,
    this.onRequestClose,
  });

  @override
  State<DetailsPopupContent> createState() => _DetailsPopupContentState();
}

class _DetailsPopupContentState extends State<DetailsPopupContent> {
  bool _isPro = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  void _close() {
    if (_isClosing) return;
    _isClosing = true;
    // Prefer callback if provided so the parent can handle the overlay dismissal
    if (widget.onRequestClose != null) {
      widget.onRequestClose!();
      return;
    }
    // Fallback: try closing any enclosing route if present
    if (Navigator.of(context).canPop()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _checkProStatus() async {
    final isPro = await EntitlementsService.instance.isPro();
    if (mounted) {
      setState(() {
        _isPro = isPro;
      });
    }
  }

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
                    if (widget.quote.tags.isEmpty)
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
                        children: widget.quote.tags.map((tag) {
                          return widget.buildTagChip(
                            tag,
                            onTap: (selectedTag) {
                              _close();
                              widget.onTagToggled(selectedTag);
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
                    _buildGatedAuthorChip(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGatedAuthorChip() {
    if (_isPro) {
      // Pro users get normal author chip functionality
      return widget.buildAuthorChip(
        widget.quote.authorName,
        onTap: (selectedAuthor) {
          _close();
          widget.onAuthorToggled(selectedAuthor);
        },
      );
    } else {
      // Free users get grayed out chip that opens paywall
      return GestureDetector(
        onTap: () {
          _close();
          openPaywall(context: context, contextKey: 'browse_author');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.quote.authorName,
                style: TextStyle(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'EBGaramond',
                ),
              ),
              const SizedBox(width: 6.0),
              Icon(
                Icons.lock_outline,
                size: 14.0,
                color: Theme.of(context).primaryColor.withOpacity(0.4),
              ),
            ],
          ),
        ),
      );
    }
  }
}
