import 'package:flutter/material.dart';
import 'package:quotes_app/theme/lb_theme_extension.dart';

// Theme IDs
const String lightThemeId = 'light';
const String darkThemeId = 'dark';
const String sandThemeId = 'sand';
const String inkThemeId = 'ink';
const String roseThemeId = 'rose';
const String noirThemeId = 'noir';

// Font IDs
const String garamondFontId = 'garamond';
const String ptSansNarrowFontId = 'pt_sans_narrow';
const String tangerineFontId = 'tangerine';

class ThemeRegistry {
  static final Map<String, ThemeData> _themes = {
    lightThemeId: _buildLightTheme(),
    darkThemeId: _buildDarkTheme(),
    sandThemeId: _buildSandTheme(),
    inkThemeId: _buildInkTheme(),
    roseThemeId: _buildRoseTheme(),
    noirThemeId: _buildNoirTheme(),
  };

  static final Map<String, String> _fonts = {
    garamondFontId: 'EBGaramond',
    ptSansNarrowFontId: 'PTSansNarrow',
    tangerineFontId: 'Tangerine',
  };

  static ThemeData getTheme(String themeId, String fontId) {
    final baseTheme = _themes[themeId] ?? _buildLightTheme();
    final fontFamily = _fonts[fontId] ?? 'EBGaramond';

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: fontFamily),
    );
  }

  static ThemeData _buildLightTheme() {
    const paper = Color(0xFFF4EFE8); // warm paper
    const primary = Color(0xFF333333); // soft charcoal

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: paper,
      dividerColor: Color(0x1F000000), // ~12% black
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: primary,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        background: paper,
      ),
      fontFamily: 'EBGaramond',
      extensions: const <ThemeExtension<dynamic>>[
        LBTheme(
          controlSurface: Color.fromARGB(255, 234, 227, 218),
          controlOnSurface: Color.fromARGB(255, 30, 30, 30),
          controlBorder: Color.fromARGB(20, 0, 0, 0),
        ),
      ],
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.white,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.white,
        brightness: Brightness.dark,
        background: Colors.black,
      ),
      fontFamily: 'EBGaramond',
      extensions: const <ThemeExtension<dynamic>>[
        LBTheme(
          controlSurface: Color.fromARGB(255, 30, 30, 30),
          controlOnSurface: Color.fromARGB(255, 220, 220, 220),
          controlBorder: Color.fromARGB(20, 255, 255, 255),
        ),
      ],
    );
  }

  static ThemeData _buildSandTheme() {
    const sand = Color(0xFFF2EADD); // desaturated sand
    const primary = Color(0xFF4F3B2A); // muted walnut

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: sand,
      dividerColor: Color(0x14000000), // ~8% black
      appBarTheme: const AppBarTheme(
        backgroundColor: sand,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: primary,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        background: Color(0xFFF3EDE2), // slightly cooler sand
      ),
      extensions: const <ThemeExtension<dynamic>>[
        LBTheme(
          controlSurface: Color(0xFFE8DECE), // warm card
          controlOnSurface: Color(0xFF4F3B2A),
          controlBorder: Color(0x1A4F3B2A), // ~10% walnut
        ),
      ],
    );
  }

  static ThemeData _buildInkTheme() {
    const sheet = Color(0xFFFBFDFF); // neutral, bright “paper”
    const primary = Color(0xFF11284C); // muted navy/ink

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: sheet,
      dividerColor: Color(0x1A11284C), // ~10% ink
      appBarTheme: const AppBarTheme(
        backgroundColor: sheet,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: primary,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        background: Color(0xFFF6F8FC), // cool off-white
      ),
      extensions: const <ThemeExtension<dynamic>>[
        LBTheme(
          controlSurface: Color(0xFFEEF2FA), // cool card
          controlOnSurface: Color(0xFF102A56),
          controlBorder: Color(0x1911284C), // ~10% ink, slightly lighter
        ),
      ],
    );
  }

  static ThemeData _buildRoseTheme() {
    const vellum = Color(0xFFFFF7F9); // airy rose paper
    const primary = Color(0xFF7A2E3A); // dusty burgundy

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: vellum,
      dividerColor: Color(0x1A7A2E3A), // ~10% burgundy
      appBarTheme: const AppBarTheme(
        backgroundColor: vellum,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: primary,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        background: Color(0xFFFFF0F3), // gentle rose wash
      ),
      extensions: const <ThemeExtension<dynamic>>[
        LBTheme(
          controlSurface: Color(0xFFFBE9ED), // soft rose card
          controlOnSurface: Color(0xFF7A2E3A),
          controlBorder: Color(0x197A2E3A), // ~10% burgundy, lighter
        ),
      ],
    );
  }

  static ThemeData _buildNoirTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFFFFFFF),
      scaffoldBackgroundColor: const Color(0xFF1C1C1E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFFFFF),
        brightness: Brightness.dark,
        background: const Color(0xFF1C1C1E),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        LBTheme(
          controlSurface: Color(0xFF2C2C2E),
          controlOnSurface: Color(0xFFE5E5E7),
          controlBorder: Color.fromARGB(20, 255, 255, 255),
        ),
      ],
    );
  }
}
