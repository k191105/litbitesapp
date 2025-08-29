import 'package:flutter/material.dart';

class LBTheme extends ThemeExtension<LBTheme> {
  const LBTheme({
    required this.controlSurface,
    required this.controlOnSurface,
    required this.controlBorder,
  });

  final Color controlSurface;
  final Color controlOnSurface;
  final Color controlBorder;

  @override
  ThemeExtension<LBTheme> copyWith({
    Color? controlSurface,
    Color? controlOnSurface,
    Color? controlBorder,
  }) {
    return LBTheme(
      controlSurface: controlSurface ?? this.controlSurface,
      controlOnSurface: controlOnSurface ?? this.controlOnSurface,
      controlBorder: controlBorder ?? this.controlBorder,
    );
  }

  @override
  ThemeExtension<LBTheme> lerp(
    covariant ThemeExtension<LBTheme>? other,
    double t,
  ) {
    if (other is! LBTheme) {
      return this;
    }
    return LBTheme(
      controlSurface: Color.lerp(controlSurface, other.controlSurface, t)!,
      controlOnSurface: Color.lerp(
        controlOnSurface,
        other.controlOnSurface,
        t,
      )!,
      controlBorder: Color.lerp(controlBorder, other.controlBorder, t)!,
    );
  }

  /// Get quote text style based on theme
  TextStyle quoteTextStyle(BuildContext context, double fontSize) {
    final textTheme = Theme.of(context).textTheme.headlineSmall!;
    final isTangerine = textTheme.fontFamily == 'Tangerine';

    return textTheme.copyWith(
      fontSize: isTangerine ? fontSize * 1.4 : fontSize, // Boost Tangerine size
      fontWeight: isTangerine
          ? FontWeight.w600
          : FontWeight.w500, // Boost Tangerine weight
      color: Theme.of(context).primaryColor,
      height: 1.4,
    );
  }

  /// Get author/source text style based on theme
  TextStyle authorTextStyle(BuildContext context, double fontSize) {
    final textTheme = Theme.of(context).textTheme.titleSmall!;
    final isTangerine = textTheme.fontFamily == 'Tangerine';

    return textTheme.copyWith(
      fontSize: isTangerine ? fontSize * 1.2 : fontSize, // Boost Tangerine size
      fontWeight: isTangerine
          ? FontWeight.w600
          : FontWeight.w300, // Boost Tangerine weight
      color: const Color.fromARGB(255, 166, 165, 165),
    );
  }

  /// Get source text style based on theme
  TextStyle sourceTextStyle(BuildContext context, double fontSize) {
    final textTheme = Theme.of(context).textTheme.labelLarge!;
    final isTangerine = textTheme.fontFamily == 'Tangerine';

    return textTheme.copyWith(
      fontSize: isTangerine
          ? fontSize * 1.15
          : fontSize, // Boost Tangerine size
      fontWeight: isTangerine
          ? FontWeight.w500
          : FontWeight.w300, // Boost Tangerine weight
      color: const Color.fromARGB(255, 140, 140, 140),
      fontStyle: FontStyle.italic,
    );
  }

  /// Get button text style based on theme
  TextStyle buttonTextStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.labelLarge!.copyWith(color: Theme.of(context).primaryColor);
  }
}
