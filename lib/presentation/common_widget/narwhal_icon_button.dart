import 'package:onyxia/export.dart';

/// @ponder ponder/NarwhalIconButton.gif
class NarwhalIconButton extends StatelessWidget {
  final NarwhalIcons icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isSelected;
  final bool isPressed;
  final bool hasCaret;
  final double size;
  final bool iconSafeMode;
  final Color? iconColor;
  final String? tooltip;
  final int badgeCount;
  final Color? badgeColor;

  const NarwhalIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.enabled = true,
    this.isSelected = false,
    this.isPressed = false,
    this.hasCaret = false,
    this.size = 32,
    this.iconSafeMode = false,
    this.iconColor,
    this.tooltip,
    this.badgeCount = 0,
    this.badgeColor,
  });

  Color getIconColor(IconButtonThemeHelper theme, BuildContext context) {
    Color result = theme.iconColor(context);
    return enabled ? result : result.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper.iconButton;

    Color getBackgroundColor(Set<WidgetState> states) {
      if (!enabled) {
        return Colors.transparent;
      } else if (isPressed) {
        return theme.pressedBackgroundColor(context);
      } else if (isSelected) {
        return theme.selectedBackgroundColor(context);
      } else if (states.contains(WidgetState.pressed)) {
        return theme.pressedBackgroundColor(context);
      } else if (states.contains(WidgetState.hovered)) {
        return theme.hoveredBackgroundColor(context);
      } else {
        return theme.defaultBackgroundColor(context);
      }
    }

    final iconColorFinal = iconColor ?? getIconColor(theme, context);

    final button = SizedBox(
      width: size + (hasCaret ? 24 : 0),
      height: size,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: ButtonStyle(
          padding: WidgetStateProperty.all(const EdgeInsets.all(3)),
          backgroundColor:
              WidgetStateProperty.resolveWith<Color>(getBackgroundColor),
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.all(BorderSide.none),
          shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          mouseCursor: WidgetStateProperty.all(SystemMouseCursors.basic),
        ),
        child: hasCaret
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 2,
                children: [
                  NarwhalIcon(
                    icon,
                    size: size - (hasCaret ? 4 : 0),
                    color: iconColorFinal,
                    safeMode: iconSafeMode,
                  ),
                  NarwhalIcon(
                    (isSelected || isPressed)
                        ? NarwhalIcons.dropdownArrowUp
                        : NarwhalIcons.dropdownArrow,
                    size: 16,
                    color: getIconColor(theme, context),
                    safeMode: iconSafeMode,
                  ),
                ],
              )
            : Center(
                child: NarwhalIcon(
                  icon,
                  size: size,
                  color: iconColorFinal,
                  safeMode: iconSafeMode,
                ),
              ),
      ),
    );

    Widget child = button;

    if (tooltip != null) {
      child = Tooltip(
        message: tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        textStyle: NarwhalTextStyle(color: ThemeHelper.neutral900(context)),
        child: child,
      );
    }

    if (badgeCount > 0) {
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            top: 2,
            right: 2,
            child: IgnorePointer(
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: badgeColor ?? ThemeHelper.red(),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const NarwhalTextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return child;
  }
}
