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
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.grey.shade800,
      scaffoldBackgroundColor: const Color.fromARGB(255, 240, 234, 225),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.grey.shade800,
        brightness: Brightness.light,
        background: const Color.fromARGB(255, 240, 234, 225),
      ),
      fontFamily: 'EBGaramond',
      extensions: const <ThemeExtension<dynamic>>[
        LBTheme(
          controlSurface: Color.fromARGB(255, 230, 224, 215),
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
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF5D4037),
      scaffoldBackgroundColor: const Color(0xFFF5F5DC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5D4037),
        brightness: Brightness.light,
        background: const Color(0xFFF5F5DC),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        LBTheme(
          controlSurface: Color(0xFFEAE5D3),
          controlOnSurface: Color(0xFF5D4037),
          controlBorder: Color.fromARGB(15, 93, 64, 55),
        ),
      ],
    );
  }

  static ThemeData _buildInkTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF00008B),
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00008B),
        brightness: Brightness.light,
        background: const Color(0xFFFFFFFF),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        LBTheme(
          controlSurface: Color(0xFFF0F4FF),
          controlOnSurface: Color(0xFF00008B),
          controlBorder: Color.fromARGB(15, 0, 0, 139),
        ),
      ],
    );
  }

  static ThemeData _buildRoseTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF8B0000),
      scaffoldBackgroundColor: const Color(0xFFFFF0F5),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B0000),
        brightness: Brightness.light,
        background: const Color(0xFFFFF0F5),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        LBTheme(
          controlSurface: Color(0xFFFEE5EE),
          controlOnSurface: Color(0xFF8B0000),
          controlBorder: Color.fromARGB(15, 139, 0, 0),
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
