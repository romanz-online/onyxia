import 'package:onyxia/export.dart';

enum NarwhalButtonType { primary, secondary, light }

/// @ponder ponder/NarwhalTextButton.gif
class NarwhalButton extends StatelessWidget {
  final NarwhalIcons? leftIcon;
  final String? text;
  final NarwhalIcons? rightIcon;
  final NarwhalIcons? centerIcon;
  final VoidCallback? onTap;
  final NarwhalButtonType type;
  final bool enabled;
  final double? width;
  final double? height;
  final bool iconSafeMode;

  const NarwhalButton({
    super.key,
    this.leftIcon,
    this.text,
    this.rightIcon,
    this.centerIcon,
    this.onTap,
    this.type = NarwhalButtonType.primary,
    this.enabled = true,
    this.width,
    this.height,
    this.iconSafeMode = false,
  }) : assert(
            (centerIcon != null && leftIcon == null && rightIcon == null && (text == null || text == '')) ||
                (centerIcon == null),
            'centerIcon cannot be used with leftIcon, rightIcon, or non-empty text');

  /// Creates an icon-only button
  const NarwhalButton.iconOnly({
    super.key,
    required NarwhalIcons icon,
    this.onTap,
    this.type = NarwhalButtonType.primary,
    this.enabled = true,
    this.width,
    this.height,
    this.iconSafeMode = false,
  })  : leftIcon = null,
        text = null,
        rightIcon = null,
        centerIcon = icon;

  /// Creates a pure icon widget without button styling - just the icon with tap handling
  const NarwhalButton.pureIcon({
    super.key,
    required NarwhalIcons icon,
    this.onTap,
    this.width,
    this.height,
    this.iconSafeMode = false,
  })  : leftIcon = null,
        text = '', // Use empty string as marker for pure icon
        rightIcon = null,
        centerIcon = icon,
        type = NarwhalButtonType.primary, // Not used for pure icon
        enabled = false; // Use false as marker for pure icon (along with empty text)

  @override
  Widget build(BuildContext context) {
    final theme = switch (type) {
      NarwhalButtonType.primary => ThemeHelper.button.primary,
      NarwhalButtonType.secondary => ThemeHelper.button.secondary,
      NarwhalButtonType.light => ThemeHelper.button.light,
    };

    Color getBackgroundColor(Set<WidgetState> states) {
      if (!enabled) {
        return theme.background.disabled(context);
      } else if (states.contains(WidgetState.pressed)) {
        return theme.background.pressed(context);
      } else if (states.contains(WidgetState.hovered)) {
        return theme.background.hovered(context);
      } else {
        return theme.background.defaultColor(context);
      }
    }

    BorderSide getBorderSide(Set<WidgetState> states) {
      final Color borderColor;
      if (!enabled) {
        borderColor = theme.border.disabled(context);
      } else if (states.contains(WidgetState.pressed)) {
        borderColor = theme.border.pressed(context);
      } else if (states.contains(WidgetState.hovered)) {
        borderColor = theme.border.hovered(context);
      } else {
        borderColor = theme.border.defaultColor(context);
      }

      return BorderSide(
        color: borderColor,
        width: type == NarwhalButtonType.secondary ? 2 : 0,
      );
    }

    Color getForegroundColor() => enabled ? theme.text.defaultColor(context) : theme.text.disabled(context);

    Color getIconColor() => enabled ? theme.icon.defaultColor(context) : theme.icon.disabled(context);

    Widget buildChild() {
      // Icon-only mode
      if (centerIcon != null) {
        return Center(
          child: NarwhalIcon(
            centerIcon!,
            size: 22,
            color: getIconColor(),
            safeMode: iconSafeMode,
          ),
        );
      }

      // Text mode with optional left/right icons
      return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leftIcon != null) ...[
            NarwhalIcon(
              leftIcon!,
              size: 22,
              color: getIconColor(),
              safeMode: iconSafeMode,
            ),
            const SizedBox(width: 8),
          ],
          if (text != null && text!.isNotEmpty)
            Text(
              text!,
              style: NarwhalTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: -0.1,
                letterSpacing: 0.8,
              ),
            ),
          if (rightIcon != null) ...[
            const SizedBox(width: 8),
            NarwhalIcon(rightIcon!, size: 22, color: getIconColor(), safeMode: iconSafeMode),
          ],
        ],
      );
    }

    final button = OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color>(getBackgroundColor),
        foregroundColor: WidgetStateProperty.all(getForegroundColor()),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        side: WidgetStateProperty.resolveWith<BorderSide>(getBorderSide),
        shape: WidgetStateProperty.all(const StadiumBorder()),
      ),
      child: buildChild(),
    );

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    return button;
  }
}
