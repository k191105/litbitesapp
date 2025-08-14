import 'package:flutter/material.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              ? (isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.15))
              : (isDark ? Colors.white : Colors.black).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black).withOpacity(0.6)
                : (isDark ? Colors.white : Colors.black).withOpacity(0.3),
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'EBGaramond',
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6.0),
              Icon(
                Icons.close,
                size: 14.0,
                color: isDark ? Colors.white : Colors.black,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
