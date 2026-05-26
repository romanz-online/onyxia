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

  // TODO: remove unnecessary BuildContext arguments
  // TODO: cont. even better, switch to using themed: https://pub.dev/packages/themed

  // TODO: fix the inverted naming

  // TODO: create a better, more cohesive color palette based around charcoal/embers

  static Color accentColor() => orange();
  static Color errorColor() => NarwhalColors.error;

  static Color amber() => NarwhalColors.amber;
  static Color yellow() => NarwhalColors.yellow;
  static Color blue() => NarwhalColors.blue;
  static Color red() => NarwhalColors.red;
  static Color orange() => NarwhalColors.orange;
  static Color green() => NarwhalColors.green;
  static Color purple() => NarwhalColors.purple;
  static Color black(BuildContext context) => Colors.white;
  static Color white(BuildContext context) => Colors.black;

  static Color neutral100(BuildContext context) => NarwhalColors.neutral900;
  static Color neutral200(BuildContext context) => NarwhalColors.neutral800;
  static Color neutral300(BuildContext context) => NarwhalColors.neutral700;
  static Color neutral400(BuildContext context) => NarwhalColors.neutral600;
  static Color neutral500(BuildContext context) => NarwhalColors.neutral500;
  static Color neutral600(BuildContext context) => NarwhalColors.neutral400;
  static Color neutral700(BuildContext context) => NarwhalColors.neutral300;
  static Color neutral800(BuildContext context) => NarwhalColors.neutral200;
  static Color neutral900(BuildContext context) => NarwhalColors.neutral100;

  static Color red900(BuildContext context) => NarwhalColors.red100;
  static Color red800(BuildContext context) => NarwhalColors.red200;
  static Color red700(BuildContext context) => NarwhalColors.red300;
  static Color red600(BuildContext context) => NarwhalColors.red400;
  static Color red500(BuildContext context) => NarwhalColors.red500;
  static Color red400(BuildContext context) => NarwhalColors.red600;
  static Color red300(BuildContext context) => NarwhalColors.red700;
  static Color red200(BuildContext context) => NarwhalColors.red800;
  static Color red100(BuildContext context) => NarwhalColors.red900;

  static Color orange700(BuildContext context) => NarwhalColors.orange200;
  static Color orange600(BuildContext context) => NarwhalColors.orange300;
  static Color orange500(BuildContext context) => NarwhalColors.orange400;
  static Color orange400(BuildContext context) => NarwhalColors.orange300;
  static Color orange200(BuildContext context) => NarwhalColors.orange700;
  static Color orange100(BuildContext context) => NarwhalColors.orange800;

  static Color green700(BuildContext context) => NarwhalColors.green300;
  static Color green600(BuildContext context) => NarwhalColors.green400;
  static Color green500(BuildContext context) => NarwhalColors.green500;
  static Color green400(BuildContext context) => NarwhalColors.green600;
  static Color green300(BuildContext context) => NarwhalColors.green700;
  static Color green200(BuildContext context) => NarwhalColors.green800;
  static Color green100(BuildContext context) => NarwhalColors.green900;

  static Color blue800(BuildContext context) => NarwhalColors.blue100;
  static Color blue700(BuildContext context) => NarwhalColors.blue200;
  static Color blue600(BuildContext context) => NarwhalColors.blue300;
  static Color blue500(BuildContext context) => NarwhalColors.blue400;
  static Color blue400(BuildContext context) => NarwhalColors.blue500;
  static Color blue300(BuildContext context) => NarwhalColors.blue600;
  static Color blue200(BuildContext context) => NarwhalColors.blue700;
  static Color blue100(BuildContext context) => NarwhalColors.blue800;

  static Color purple600(BuildContext context) => NarwhalColors.purple100;
  static Color purple500(BuildContext context) => NarwhalColors.purple200;
  static Color purple400(BuildContext context) => NarwhalColors.purple300;
  static Color purple300(BuildContext context) => NarwhalColors.purple400;
  static Color purple200(BuildContext context) => NarwhalColors.purple500;
  static Color purple100(BuildContext context) => NarwhalColors.purple600;

  static const IconButtonThemeHelper iconButton = IconButtonThemeHelper();
}

class IconButtonThemeHelper {
  const IconButtonThemeHelper();

  Color defaultBackgroundColor(BuildContext context) => Colors.transparent;

  Color hoveredBackgroundColor(BuildContext context) =>
      ThemeHelper.neutral200(context);

  Color selectedBackgroundColor(BuildContext context) =>
      ThemeHelper.neutral400(context).withValues(alpha: 0.8);

  Color pressedBackgroundColor(BuildContext context) =>
      ThemeHelper.neutral400(context).withValues(alpha: 0.5);

  Color iconColor(BuildContext context) => ThemeHelper.neutral800(context);
}
