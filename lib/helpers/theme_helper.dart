import 'package:onyxia/export.dart';

class NarwhalColors {
  NarwhalColors._();

  static const neutral900 = Color(0xFF1C1C1E);
  static const neutral800 = Color(0xFF28282C);
  static const neutral700 = Color(0xFF394648);
  static const neutral600 = Color(0xFF536560);
  static const neutral500 = Color(0xFF909699);
  static const neutral400 = Color(0xFFCFD8DC);
  static const neutral300 = Color(0xFFECEFF1);
  static const neutral200 = Color(0xFFF7F9F9);
  static const neutral100 = Color(0xFFFFFFFF);

  static const blue = Color(0xFF2196F3);
  static const blue800 = Color(0xFF344F80);
  static const blue700 = Color(0xFF007CB4);
  static const blue600 = Color(0xFF699DFF);
  static const blue500 = Color(0xFF2EBEFF);
  static const blue400 = Color(0xFF8CDBFF);
  static const blue300 = Color(0xFFC8DBFF);
  static const blue200 = Color(0xFFE1F5FE);
  static const blue100 = Color(0xFFE6F8FF);

  static const green = Color(0xFF4CAF50);
  static const green900 = Color(0xFF1B5E20);
  static const green800 = Color(0xFF2E7D32);
  static const green700 = Color(0xFF388E3C);
  static const green600 = Color(0xFF43A047);
  static const green500 = Color(0xFF285C3F);
  static const green400 = Color(0xFF009142);
  static const green300 = Color(0xFF55C184);
  static const green200 = Color(0xFFA9E4C3);
  static const green100 = Color(0xFFD4F7E4);

  static const orange = Color(0xFFFF9800);
  static const orange800 = Color(0xFFEF6C00);
  static const orange700 = Color(0xFFF57C00);
  static const orange600 = Color(0xFFFB8C00);
  static const orange500 = Color(0xFFFF9800);
  static const orange400 = Color(0xFFFFA726);
  static const orange300 = Color(0xFFFFB74D);
  static const orange200 = Color(0xFFFFCC80);
  static const orange100 = Color(0xFFFBC492);

  static const red = Color(0xFFF44336);
  static const red900 = Color(0xFFB71C1C);
  static const red800 = Color(0xFFC62828);
  static const red700 = Color(0xFFD32F2F);
  static const red600 = Color(0xFFE53935);
  static const red500 = Color(0xFFF44336);
  static const red400 = Color(0xFFEF5350);
  static const red300 = Color(0xFFB55252);
  static const red200 = Color(0xFFF26D6F);
  static const red100 = Color(0xFFF8ADAE);

  static const purple = Color(0xFF9C27B0);
  static const purple600 = Color(0xFF8E24AA);
  static const purple500 = Color(0xFF9C27B0);
  static const purple400 = Color(0xFF8E24AA);
  static const purple300 = Color(0xFFBA68C8);
  static const purple200 = Color(0xFFC97DC7);
  static const purple100 = Color(0xFFE3C0E1);

  static const yellow = Color(0xFFFFEB3B);
  static const amber = Color(0xFFFFC107);
  static const error = Color(0xFFE53935);
}

/// A helper class for getting theme-aware colors.
class ThemeHelper {
  ThemeHelper._();

  // TODO: come up with a handful of colors that i can reliably reuse everywhere, probably no more than 10 but realistically closer to 6, which will be much more easy to swap out

  // background color 1 (primary background everywhere)
  // background color 2 (slightly lighter background to contrast with primary background)
  // auxiliary color (for tooltips, probably other stuff, meant to stand out from both background colors)
  // foreground color 1 (primary color used for bard editor, popup menu text/icons)
  // foreground color 2 (secondary text color for artifact tree names (currently used for the trailing extension text), most icons outside of popup menus)
  // accent color (highlights, hyperlinks)
  // error color (error text and error speech bubbles)

  // TODO: simplify current color palette into these values
  // background 1: neutral900
  // background 2: neutral800
  // auxiliary: neutral700
  // foreground 1: neutral300
  // foreground 2: neutral500
  // accent: NarwhalColors.orange
  // error: red500

  // TODO: create a better, more cohesive color palette based around charcoal/embers called "onyxia" (drop the narwhal theme entirely). best i've found so far is #222831 #393E46 #B55400/#FF7700 #EEEEEE as a base and it needs some shade variants defined in a cohesive theme template that i can reuse for other themes easily WITHOUT relying on the materal them stupidity

  // TODO: switch to using themed: https://pub.dev/packages/themed and let users switch between them on the fly. use "slumber" as a second theme, #051622 #1BA098 #DEB992

  static Color accentColor() => orange();
  static Color errorColor() => NarwhalColors.red500;

  static Color amber() => NarwhalColors.amber;
  static Color yellow() => NarwhalColors.yellow;
  static Color red() => NarwhalColors.red;
  static Color orange() => NarwhalColors.orange;
  static Color black() => Colors.black;
  static Color white() => Colors.white;

  static Color neutral100() => NarwhalColors.neutral100;
  static Color neutral200() => NarwhalColors.neutral200;
  static Color neutral300() => NarwhalColors.neutral300;
  static Color neutral400() => NarwhalColors.neutral400;
  static Color neutral500() => NarwhalColors.neutral500;
  static Color neutral600() => NarwhalColors.neutral600;
  static Color neutral700() => NarwhalColors.neutral700;
  static Color neutral800() => NarwhalColors.neutral800;
  static Color neutral900() => NarwhalColors.neutral900;

  static Color blue400() => NarwhalColors.blue400;
  static Color blue500() => NarwhalColors.blue500;
}
