import 'package:onyxia/export.dart';
import 'package:themed/themed.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeVariant>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeVariant> {
  @override
  ThemeVariant build() => ThemeVariant.onyxia;

  void set(ThemeVariant variant) {
    state = variant;
    Themed.currentTheme = ThemeHelper.paletteFor(variant);
  }

  void toggle() {
    set(
      state == ThemeVariant.onyxia ? ThemeVariant.slumber : ThemeVariant.onyxia,
    );
  }
}
