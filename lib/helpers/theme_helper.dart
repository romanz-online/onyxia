import 'package:onyxia/export.dart';
import 'package:themed/themed.dart';

// TODO: add more themes

// TODO: add a proper theme menu in the project settings overlay that doesn't exist yet

// TODO: add foreground3. should be used for trailing extension text and certain icons

enum ThemeVariant { onyxia, slumber }

/// A helper class for getting theme-aware colors. Each method returns a
/// [ColorRef] (which `extends Color`) whose resolved RGB depends on the
/// active [ThemeVariant]. Switch themes via `themeProvider`'s `set`/`toggle`.
class ThemeHelper {
  ThemeHelper._();

  static const ColorRef _background1 = ColorRef(
    const Color(0xFF1F2329),
    id: 'background1',
  );
  static const ColorRef _background2 = ColorRef(
    const Color(0xFF34383F),
    id: 'background2',
  );
  static const ColorRef _auxiliary = ColorRef(
    const Color(0xFF494D54),
    id: 'auxiliary',
  );
  static const ColorRef _foreground1 = ColorRef(
    const Color(0xFFEEEEEE),
    id: 'foreground1',
  );
  static const ColorRef _foreground2 = ColorRef(
    const Color(0xFF969A9F),
    id: 'foreground2',
  );
  static const ColorRef _accent = ColorRef(
    const Color(0xFFF17D16),
    id: 'accent',
  );
  static const ColorRef _error = ColorRef(const Color(0xFFF03E3E), id: 'error');

  static Color background1() => _background1;
  static Color background2() => _background2;
  static Color auxiliary() => _auxiliary;
  static Color foreground1() => _foreground1;
  static Color foreground2() => _foreground2;
  static Color accent() => _accent;
  static Color error() => _error;

  static final Map<ThemeRef, Object> _onyxia = {
    _background1: const Color(0xFF1F2329),
    _background2: const Color(0xFF34383F),
    _auxiliary: const Color(0xFF494D54),
    _foreground1: const Color(0xFFEEEEEE),
    _foreground2: const Color(0xFFB4B8BD),
    _accent: const Color(0xFFF17D16),
    _error: const Color(0xFFF03E3E),
  };

  static final Map<ThemeRef, Object> _slumber = {
    _background1: const Color(0xFF051622),
    _background2: const Color(0xFF0A2230),
    _auxiliary: const Color(0xFF1BA098),
    _foreground1: const Color(0xFFEEEEEE),
    _foreground2: const Color(0xFF969A9F),
    _accent: const Color(0xFFDEB992),
    _error: const Color(0xFFF03E3E),
  };

  static Map<ThemeRef, Object> paletteFor(ThemeVariant variant) =>
      switch (variant) {
        .onyxia => _onyxia,
        .slumber => _slumber,
      };
}
