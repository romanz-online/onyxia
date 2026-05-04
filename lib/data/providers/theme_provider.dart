import 'package:onyxia/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing app theme (light/dark mode)
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) => ThemeNotifier());

/// Notifier class to handle theme state changes
class ThemeNotifier extends StateNotifier<bool> {
  /// Key for storing theme preference
  static const String _themePreferenceKey = 'is_dark_mode';

  /// Constructor with default value (true = dark mode, false = light mode)
  /// Loads saved preference or defaults to light mode
  ThemeNotifier() : super(false) {
    _loadThemePreference();
  }

  /// Load saved theme preference
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_themePreferenceKey) ?? true;
    } catch (e) {
      debugPrint('Error loading theme preference - $e');
      // If there's an error accessing preferences, default to light mode
      state = false;
    }
  }

  /// Save theme preference
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePreferenceKey, state);
    } catch (e) {
      debugPrint('ThemeNotifier: Error saving theme preference - $e');
      // Handle error silently - will be restored on next app launch
    }
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
