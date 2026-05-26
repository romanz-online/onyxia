import 'package:onyxia/export.dart';

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

class ButtonPropertyTheme {
  final Color Function(BuildContext) _defaultColor;
  final Color Function(BuildContext) _hoveredColor;
  final Color Function(BuildContext) _pressedColor;
  final Color Function(BuildContext) _disabledColor;

  const ButtonPropertyTheme({
    required Color Function(BuildContext) defaultColor,
    required Color Function(BuildContext) hoveredColor,
    required Color Function(BuildContext) pressedColor,
    required Color Function(BuildContext) disabledColor,
  })  : _defaultColor = defaultColor,
        _hoveredColor = hoveredColor,
        _pressedColor = pressedColor,
        _disabledColor = disabledColor;

  Color defaultColor(BuildContext context) => _defaultColor(context);
  Color hovered(BuildContext context) => _hoveredColor(context);
  Color pressed(BuildContext context) => _pressedColor(context);
  Color disabled(BuildContext context) => _disabledColor(context);
}

class ButtonTypeTheme {
  final ButtonPropertyTheme background;
  final ButtonPropertyTheme border;
  final ButtonPropertyTheme text;
  final ButtonPropertyTheme icon;

  const ButtonTypeTheme({
    required this.background,
    required this.border,
    required this.text,
    required this.icon,
  });
}

class ButtonThemeHelper {
  const ButtonThemeHelper();

  static Color _mainColor(BuildContext context) => ThemeHelper.blue700(context);

  static Color _accentColor(BuildContext context) =>
      ThemeHelper.neutral100(context);

  static Color _accentSecondaryColor(BuildContext context) =>
      ThemeHelper.neutral800(context);

  static Color _none(BuildContext context) => Colors.transparent;

  static Color _brighten(Color color) => Color.lerp(color, Colors.white, 0.2)!;

  static Color _darken(Color color) => Color.lerp(color, Colors.black, 0.2)!;

  static Color _disabledColor(BuildContext context) =>
      ThemeHelper.neutral400(context);

  ButtonTypeTheme get primary => ButtonTypeTheme(
        background: ButtonPropertyTheme(
          defaultColor: _mainColor,
          hoveredColor: (context) => _brighten(_mainColor(context)),
          pressedColor: (context) => _darken(_mainColor(context)),
          disabledColor: _disabledColor,
        ),
        border: ButtonPropertyTheme(
          defaultColor: _none,
          hoveredColor: _none,
          pressedColor: _none,
          disabledColor: _none,
        ),
        text: ButtonPropertyTheme(
          defaultColor: _accentColor,
          hoveredColor: _accentColor,
          pressedColor: _accentColor,
          disabledColor: _accentColor,
        ),
        icon: ButtonPropertyTheme(
          defaultColor: _accentColor,
          hoveredColor: _accentColor,
          pressedColor: _accentColor,
          disabledColor: _accentColor,
        ),
      );

  ButtonTypeTheme get secondary => ButtonTypeTheme(
        background: ButtonPropertyTheme(
          defaultColor: _none,
          hoveredColor: ThemeHelper.blue100,
          pressedColor: ThemeHelper.blue400,
          disabledColor: _none,
        ),
        border: ButtonPropertyTheme(
          defaultColor: _mainColor,
          hoveredColor: (context) => _brighten(_mainColor(context)),
          pressedColor: (context) => _darken(_mainColor(context)),
          disabledColor: _disabledColor,
        ),
        text: ButtonPropertyTheme(
          defaultColor: _accentSecondaryColor,
          hoveredColor: _accentSecondaryColor,
          pressedColor: _accentSecondaryColor,
          disabledColor: _disabledColor,
        ),
        icon: ButtonPropertyTheme(
          defaultColor: _accentSecondaryColor,
          hoveredColor: _accentSecondaryColor,
          pressedColor: _accentSecondaryColor,
          disabledColor: _disabledColor,
        ),
      );

  ButtonTypeTheme get light => ButtonTypeTheme(
        background: ButtonPropertyTheme(
          defaultColor: _none,
          hoveredColor: (context) => ThemeHelper.neutral300(context),
          pressedColor: (context) => ThemeHelper.neutral400(context),
          disabledColor: _none,
        ),
        border: ButtonPropertyTheme(
          defaultColor: _none,
          hoveredColor: _none,
          pressedColor: _none,
          disabledColor: _none,
        ),
        text: ButtonPropertyTheme(
          defaultColor: _mainColor,
          hoveredColor: _mainColor,
          pressedColor: _mainColor,
          disabledColor: _disabledColor,
        ),
        icon: ButtonPropertyTheme(
          defaultColor: _accentSecondaryColor,
          hoveredColor: _accentSecondaryColor,
          pressedColor: _accentSecondaryColor,
          disabledColor: _disabledColor,
        ),
      );
}

class SubSectionButtonThemeHelper {
  const SubSectionButtonThemeHelper();

  Color defaultBackgroundColor(BuildContext context) =>
      ThemeHelper.neutral200(context);

  Color hoveredBackgroundColor(BuildContext context) =>
      ThemeHelper.neutral300(context);

  Color selectedBackgroundColor(BuildContext context) =>
      ThemeHelper.blue400(context).withValues(alpha: 0.5);

  Color pressedBackgroundColor(BuildContext context) =>
      ThemeHelper.neutral400(context);

  Color textColor(BuildContext context) => Colors.white;
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
