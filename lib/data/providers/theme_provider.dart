import 'package:onyxia/export.dart';
import 'package:themed/themed.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeVariant>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeVariant> {
  @override
  ThemeVariant build() => .onyxia;

  void set(ThemeVariant variant) {
    if (state == variant) return;
    state = variant;
    Themed.currentTheme = ThemeHelper.paletteFor(variant);
  }
}
