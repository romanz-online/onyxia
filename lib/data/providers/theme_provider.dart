import 'package:onyxia/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme (light/dark mode)
final themeProvider =
    NotifierProvider<ThemeNotifier, bool>(ThemeNotifier.new);

/// Notifier class to handle theme state changes
class ThemeNotifier extends Notifier<bool> {
  static const String _themePreferenceKey = 'is_dark_mode';

  @override
  bool build() {
    _loadThemePreference();
    return false;
  }

  /// Load saved theme preference
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_themePreferenceKey) ?? true;
  }

  /// Save theme preference
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePreferenceKey, state);
  }

  /// Toggle between light and dark mode
  void toggleTheme() {
    state = !state;
    _saveThemePreference();
  }

  /// Set specific theme mode
  void setDarkMode(bool isDark) {
    state = isDark;
    _saveThemePreference();
  }
}
