import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quotes_app/theme/theme_registry.dart';
import 'package:quotes_app/services/entitlements_service.dart';

class ThemeController {
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  static const String _themeIdKey = 'theme_id';
  static const String _fontIdKey = 'font_id';
  static const String _lastFreeThemeIdKey = 'last_free_theme_id';

  late String _themeId;
  late String _fontId;

  ThemeData get themeData => ThemeRegistry.getTheme(_themeId, _fontId);
  String get themeId => _themeId;
  String get fontId => _fontId;

  final List<VoidCallback> _listeners = [];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeId = prefs.getString(_themeIdKey) ?? lightThemeId;
    final savedFontId = prefs.getString(_fontIdKey) ?? garamondFontId;

    // Validate theme access for former Pro users
    _themeId = await _validateThemeAccess(savedThemeId);
    _fontId = await _validateFontAccess(savedFontId);

    // Save corrected values if they were changed
    if (_themeId != savedThemeId) {
      await prefs.setString(_themeIdKey, _themeId);
    }
    if (_fontId != savedFontId) {
      await prefs.setString(_fontIdKey, _fontId);
    }
  }

  Future<String> _validateThemeAccess(String themeId) async {
    final freeThemes = [lightThemeId, darkThemeId];
    if (freeThemes.contains(themeId)) {
      return themeId; // Free theme, always accessible
    }

    // Premium theme - check access
    final hasAccess = await EntitlementsService.instance.isFeatureActive(
      'premium_themes',
    );
    if (hasAccess) {
      return themeId; // User has access, keep the theme
    }

    // No access to premium theme, fall back to light theme
    return lightThemeId;
  }

  Future<String> _validateFontAccess(String fontId) async {
    final freeFonts = [garamondFontId];
    if (freeFonts.contains(fontId)) {
      return fontId; // Free font, always accessible
    }

    // Premium fonts - check access
    final hasAccess = await EntitlementsService.instance.isFeatureActive(
      'premium_fonts',
    );
    if (hasAccess) {
      return fontId; // User has access, keep the font
    }

    // No access to premium font, fall back to garamond
    return garamondFontId;
  }

  Future<void> setTheme(String themeId) async {
    _themeId = themeId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeIdKey, themeId);
    // Remember last free theme to respect user's preference when passes expire
    if (_isFreeTheme(themeId)) {
      await prefs.setString(_lastFreeThemeIdKey, themeId);
    }
    _notifyListeners();
  }

  Future<void> setFont(String fontId) async {
    _fontId = fontId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontIdKey, fontId);
    _notifyListeners();
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  bool _isFreeTheme(String themeId) {
    return themeId == lightThemeId || themeId == darkThemeId;
  }

  /// Revert to the user's last chosen free theme (defaults to light).
  Future<void> revertToLastFreeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFree = prefs.getString(_lastFreeThemeIdKey) ?? lightThemeId;
    await setTheme(lastFree);
  }
}
