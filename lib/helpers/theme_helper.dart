import 'package:onyxia/export.dart';

/// A helper class for getting theme-aware colors based on the current brightness
class ThemeHelper {
  ThemeHelper._();

  /// Get the bluecolor
  static Color blue800(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.blue100 : NarwhalColors.blue800;
  }

  /// Get the bluecolor
  static Color blue500(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.blue400 : NarwhalColors.blue500;
  }

  /// Get the bluecolor
  static Color blue400(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.blue500 : NarwhalColors.blue400;
  }

  /// Get the bluecolor
  static Color blue700(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.blue200 : NarwhalColors.blue700;
  }

  /// Get the bluecolor
  static Color blue200(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.blue700 : NarwhalColors.blue200;
  }

  /// Get the bluecolor
  static Color blue100(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.blue800 : NarwhalColors.blue100;
  }

  static Color amber() {
    return NarwhalColors.amber;
  }

  static Color yellow() {
    return NarwhalColors.yellow;
  }

  static Color errorColor() {
    return NarwhalColors.error;
  }

  /// Get the neutral100  color
  static Color neutral100(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.neutral900 : NarwhalColors.neutral100;
  }

  /// Get the neutral200  color
  static Color neutral200(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.neutral800 : NarwhalColors.neutral200;
  }

  /// Get the neutral300  color
  static Color neutral300(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.neutral700 : NarwhalColors.neutral300;
  }

  /// Get the neutral400  color
  static Color neutral400(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.neutral600 : NarwhalColors.neutral400;
  }

  /// Get the neutral500  color
  static Color neutral500(BuildContext context) {
    return NarwhalColors.neutral500;
  }

  /// Get the neutral600  color
  static Color neutral600(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.neutral400 : NarwhalColors.neutral600;
  }

  static Color neutral700(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.neutral300 : NarwhalColors.neutral700;
  }

  /// Get the neutral800  color
  static Color neutral800(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.neutral200 : NarwhalColors.neutral800;
  }

  /// Get the neutral900  color
  static Color neutral900(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.neutral100 : NarwhalColors.neutral900;
  }

  static Color blue() {
    return NarwhalColors.blue;
  }

  static Color red() {
    return NarwhalColors.red;
  }

  static Color red900(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.red100 : NarwhalColors.red900;
  }

  static Color red800(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.red200 : NarwhalColors.red800;
  }

  static Color red700(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.red300 : NarwhalColors.red700;
  }

  static Color red600(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.red400 : NarwhalColors.red600;
  }

  static Color red500(BuildContext context) {
    return NarwhalColors.red500;
  }

  static Color red400(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.red600 : NarwhalColors.red400;
  }

  static Color red300(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.red700 : NarwhalColors.red300;
  }

  /// Get the red200 color
  static Color red200(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.red800 : NarwhalColors.red200;
  }

  /// Get the red100 color
  static Color red100(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.red900 : NarwhalColors.red100;
  }

  static Color orange() {
    return NarwhalColors.orange;
  }

  static Color orange700(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.orange200 : NarwhalColors.orange700;
  }

  static Color orange600(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.orange300 : NarwhalColors.orange600;
  }

  static Color orange500(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.orange400 : NarwhalColors.orange500;
  }

  static Color orange400(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.orange300 : NarwhalColors.orange400;
  }

  /// Get the orange200 color
  static Color orange200(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.orange700 : NarwhalColors.orange200;
  }

  /// Get the orange100 color
  static Color orange100(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.orange800 : NarwhalColors.orange100;
  }

  static Color green() {
    return NarwhalColors.green;
  }

  static Color green700(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.green300 : NarwhalColors.green700;
  }

  static Color green600(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.green400 : NarwhalColors.green600;
  }

  static Color green500(BuildContext context) {
    return NarwhalColors.green500;
  }

  static Color green400(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.green600 : NarwhalColors.green400;
  }

  /// Get the green300 color
  static Color green300(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.green700 : NarwhalColors.green300;
  }

  /// Get the green200 color
  static Color green200(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.green800 : NarwhalColors.green200;
  }

  static Color green100(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.green900 : NarwhalColors.green100;
  }

  /// Get the blue600 color
  static Color blue600(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.blue300 : NarwhalColors.blue600;
  }

  /// Get the blue300 color
  static Color blue300(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.blue600 : NarwhalColors.blue300;
  }

  static Color purple() {
    return NarwhalColors.purple;
  }

  static Color purple600(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.purple100 : NarwhalColors.purple600;
  }

  static Color purple500(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.purple200 : NarwhalColors.purple500;
  }

  static Color purple400(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.purple300 : NarwhalColors.purple400;
  }

  static Color purple300(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.purple400 : NarwhalColors.purple300;
  }

  /// Get the purple200 color
  static Color purple200(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.purple500 : NarwhalColors.purple200;
  }

  /// Get the purple100 color
  static Color purple100(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? NarwhalColors.purple600 : NarwhalColors.purple100;
  }

  static Color black(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.white : Colors.black;
  }

  static Color white(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.black : Colors.white;
  }

  /// Returns the primary accent blue, adjusted for legibility in dark mode
  static Color accentColor() {
    return orange();
  }

  /// NarwhalButton-specific theme helper
  static const ButtonThemeHelper button = ButtonThemeHelper();

  /// SubSection button-specific theme helper
  static const SubSectionButtonThemeHelper subSectionButton = SubSectionButtonThemeHelper();

  /// Icon button-specific theme helper
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

  static Color _accentColor(BuildContext context) => ThemeHelper.neutral100(context);

  static Color _accentSecondaryColor(BuildContext context) => ThemeHelper.neutral800(context);

  static Color _none(BuildContext context) => Colors.transparent;

  static Color _brighten(Color color) => Color.lerp(color, Colors.white, 0.2)!;

  static Color _darken(Color color) => Color.lerp(color, Colors.black, 0.2)!;

  static Color _disabledColor(BuildContext context) => ThemeHelper.neutral400(context);

  ButtonTypeTheme get primary => ButtonTypeTheme(
        background: ButtonPropertyTheme(
          defaultColor: _mainColor,
          hoveredColor: (context) {
            return _brighten(_mainColor(context));
          },
          pressedColor: (context) {
            return _darken(_mainColor(context));
          },
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
          hoveredColor: (context) {
            return _brighten(_mainColor(context));
          },
          pressedColor: (context) {
            return _darken(_mainColor(context));
          },
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

  Color defaultBackgroundColor(BuildContext context) => ThemeHelper.neutral200(context);

  Color hoveredBackgroundColor(BuildContext context) => ThemeHelper.neutral300(context);

  Color selectedBackgroundColor(BuildContext context) => ThemeHelper.blue400(context).withValues(alpha: 0.5);

  Color pressedBackgroundColor(BuildContext context) => ThemeHelper.neutral400(context);

  Color textColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? Colors.white : Colors.black;
  }
}

class IconButtonThemeHelper {
  const IconButtonThemeHelper();

  Color defaultBackgroundColor(BuildContext context) => Colors.transparent;

  Color hoveredBackgroundColor(BuildContext context) => ThemeHelper.neutral200(context);

  Color selectedBackgroundColor(BuildContext context) => ThemeHelper.neutral400(context).withValues(alpha: 0.8);

  Color pressedBackgroundColor(BuildContext context) => ThemeHelper.neutral400(context).withValues(alpha: 0.5);

  Color iconColor(BuildContext context) => ThemeHelper.neutral800(context);
}
