import 'package:flutter/material.dart';
import 'package:quotes_app/theme/lb_theme_extension.dart';

class TagChip extends StatelessWidget {
  final String tag;
  final bool isSelected;
  final void Function(String)? onTap;

  const TagChip({
    super.key,
    required this.tag,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lbTheme = Theme.of(context).extension<LBTheme>();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!(tag);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.12)
              : lbTheme?.controlSurface ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : lbTheme?.controlBorder ??
                      colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6.0),
              Icon(Icons.close, size: 14.0, color: colorScheme.primary),
            ],
          ],
        ),
      ),
    );
  }
}
