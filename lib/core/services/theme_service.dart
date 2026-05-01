import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service for managing theme preferences
class ThemeService {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';
  
  static Box? _box;

  /// Initialize the settings box
  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Get the settings box
  static Box get box {
    if (_box == null) {
      throw Exception('ThemeService not initialized. Call ThemeService.init() first.');
    }
    return _box!;
  }

  /// Get saved theme mode from local storage
  static ThemeMode getSavedThemeMode() {
    try {
      final savedTheme = box.get(_themeKey, defaultValue: 'system');
      
      switch (savedTheme) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (e) {
      // If box is not initialized, return system default
      return ThemeMode.system;
    }
  }

  /// Save theme mode to local storage
  static Future<void> saveThemeMode(ThemeMode mode) async {
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    
    await box.put(_themeKey, themeString);
  }
}

/// Theme mode notifier that persists changes
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeService.getSavedThemeMode());

  /// Update theme mode and persist to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ThemeService.saveThemeMode(mode);
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}

/// Provider for theme mode with persistence
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);
