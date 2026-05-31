import 'package:onyxia/export.dart';
import 'package:themed/themed.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeVariant>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeVariant> {
  @override
  ThemeVariant build() {
    _loadSaved();
    return .onyxia;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme');
    if (saved == null) return;
    final variant = ThemeVariant.values.firstWhere(
      (v) => v.name == saved,
      orElse: () => .onyxia,
    );
    state = variant;
    Themed.currentTheme = ThemeHelper.paletteFor(variant);
  }

  Future<void> set(ThemeVariant variant) async {
    if (state == variant) return;
    state = variant;
    Themed.currentTheme = ThemeHelper.paletteFor(variant);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', variant.name);
  }
}
