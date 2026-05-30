import 'package:onyxia/export.dart';
import 'package:themed/themed.dart';

enum ThemeVariant with OnyxiaEnum {
  onyxia('Onyxia'),
  slumber('Slumber'),
  wedding('Wedding'),
  coffee('Coffee');

  final String label;
  const ThemeVariant(this.label);
}

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
    const Color(0xFFCACDD1),
    id: 'foreground2',
  );
  static const ColorRef _foreground3 = ColorRef(
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
  static Color foreground3() => _foreground3;
  static Color accent() => _accent;
  static Color error() => _error;

  static final Map<ThemeRef, Object> _onyxia = {
    _background1: const Color(0xFF1F2329),
    _background2: const Color(0xFF34383F),
    _auxiliary: const Color(0xFF494D54),
    _foreground1: const Color(0xFFEEEEEE),
    _foreground2: const Color(0xFFCACDD1),
    _foreground3: const Color(0xFFB4B8BD),
    _accent: const Color(0xFFF17D16),
    _error: const Color(0xFFF03E3E),
  };

  static final Map<ThemeRef, Object> _slumber = {
    _background1: const Color(0xFF051622),
    _background2: const Color(0xFF0A2230),
    _auxiliary: const Color(0xFF1BA098),
    _foreground1: const Color(0xFFEEEEEE),
    _foreground2: const Color(0xFFCACDD1),
    _foreground3: const Color(0xFF969A9F),
    _accent: const Color(0xFFDEB992),
    _error: const Color(0xFFF03E3E),
  };

  static final Map<ThemeRef, Object> _wedding = {
    _background1: const Color(0xFF13334C),
    _background2: const Color(0xFF005792),
    _auxiliary: const Color.fromARGB(255, 0, 117, 196),
    _foreground1: const Color(0xFFF6F6E9),
    _foreground2: const Color(0xFFDDDDCE),
    _foreground3: const Color(0xFFBBBBAC),
    _accent: const Color(0xFFFD5F00),
    _error: const Color(0xFFF03E3E),
  };

  static final Map<ThemeRef, Object> _coffee = {
    _background1: const Color.fromARGB(255, 39, 58, 77),
    _background2: const Color(0xFF42576B),
    _auxiliary: const Color(0xFF7E8A97),
    _foreground1: const Color(0xFFE7DEC8),
    _foreground2: const Color(0xFFC5BCA6),
    _foreground3: const Color(0xFFA79E88),
    _accent: const Color(0xFFCBAF87),
    _error: const Color(0xFFF03E3E),
  };

  static Map<ThemeRef, Object> paletteFor(ThemeVariant variant) =>
      switch (variant) {
        .onyxia => _onyxia,
        .slumber => _slumber,
        .wedding => _wedding,
        .coffee => _coffee,
      };
}
