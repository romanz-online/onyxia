import 'package:onyxia/export.dart';

class NarwhalColors {
  NarwhalColors._();

  static const neutral900 = const Color(0xFF1C1C1E);
  // static const neutral800 = const Color(0xFF28282C);
  // static const neutral700 = const Color(0xFF394648);
  static const neutral600 = const Color(0xFF536560);
  static const neutral500 = const Color(0xFF909699);
  static const neutral400 = const Color(0xFFCFD8DC);
  static const neutral300 = const Color(0xFFECEFF1);
  // static const neutral200 = const Color(0xFFF7F9F9);
  static const neutral100 = const Color(0xFFFFFFFF);

  static const blue600 = const Color(0xFF699DFF);
  static const blue300 = const Color(0xFFC8DBFF);

  static const green800 = const Color(0xFF2E7D32);
  static const green700 = const Color(0xFF388E3C);

  static const orange800 = const Color(0xFFEF6C00);
  static const orange700 = const Color(0xFFF57C00);

  static const red900 = const Color(0xFFB71C1C);
  static const red800 = const Color(0xFFC62828);

  static const purple600 = const Color(0xFF8E24AA);
  static const purple500 = const Color(0xFF9C27B0);
}

/// A helper class for getting theme-aware colors.
class ThemeHelper {
  ThemeHelper._();

  // TODO: create a better, more cohesive color palette based around charcoal/embers called "onyxia" (drop the narwhal theme entirely). best i've found so far is #222831 #393E46 #FF7700 #EEEEEE as a base and it needs some shade variants defined in a cohesive theme template that i can reuse for other themes easily WITHOUT relying on the materal them stupidity

  // TODO: switch to using themed: https://pub.dev/packages/themed and let users switch between them on the fly. use "slumber" as a second theme, #051622 #1BA098 #DEB992

  static Color background1() => const Color(0xFF1C1C1E);
  static Color background2() => const Color(0xFF28282C);
  static Color auxiliary() => const Color(0xFF394648);
  static Color foreground1() => const Color(0xFFF7F9F9);
  static Color foreground2() => const Color(0xFF909699);
  static Color accent() => const Color(0xFFFF9800);
  static Color error() => const Color(0xFFF44336);
}
