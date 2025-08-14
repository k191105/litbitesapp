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
}
