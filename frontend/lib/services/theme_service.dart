import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

/// Global theme controller — singleton, access via [themeService].
///
/// Persists the user's preference in SharedPreferences under [_prefsKey].
/// Default is [AppThemeMode.system] (follow the OS setting).
class ThemeService extends ChangeNotifier {
  static const _prefsKey = 'app_theme_mode';

  AppThemeMode _mode = AppThemeMode.system;

  AppThemeMode get mode => _mode;

  ThemeMode get themeMode => switch (_mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };

  /// Load persisted preference. Call once before [runApp].
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      _mode = AppThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => AppThemeMode.system,
      );
    }
  }

  /// Update mode and persist to SharedPreferences.
  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}

/// App-wide singleton.
final themeService = ThemeService();
