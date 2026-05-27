import 'package:onyxia/export.dart';

class OnyxiaIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isSelected;
  final bool isPressed;
  final bool hasCaret;
  final double size;
  final Color? iconColor;
  final String? tooltip;

  /// Side of the button the tooltip appears on. Null = auto-pick based on
  /// viewport room. Pass explicitly for buttons near a viewport edge
  /// (e.g. left-edge sidebar buttons want `right`).
  final OnyxiaTooltipDirection? tooltipDirection;
  final int badgeCount;
  final Color? badgeColor;

  const OnyxiaIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.enabled = true,
    this.isSelected = false,
    this.isPressed = false,
    this.hasCaret = false,
    this.size = 28,
    this.iconColor,
    this.tooltip,
    this.tooltipDirection,
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
          padding: .all(.all(3)),
          backgroundColor: .resolveWith<Color>(getBackgroundColor),
          overlayColor: .all(Colors.transparent),
          side: .all(BorderSide.none),
          shape: .all(RoundedRectangleBorder(borderRadius: .circular(8))),
          mouseCursor: .all(SystemMouseCursors.basic),
        ),
        child: hasCaret
            ? Row(
                mainAxisSize: .min,
                mainAxisAlignment: .center,
                spacing: 2,
                children: [
                  Icon(icon, size: size - 4, color: iconColorFinal),
                  Icon(
                    (isSelected || isPressed)
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 16,
                    color: getIconColor(theme, context),
                  ),
                ],
              )
            : Center(
                child: Icon(icon, size: size - 8, color: iconColorFinal),
              ),
      ),
    );

    Widget child = button;

    if (tooltip != null) {
      child = OnyxiaTooltip(
        message: tooltip!,
        direction: tooltipDirection,
        child: child,
      );
    }

    if (badgeCount > 0) {
      child = Stack(
        clipBehavior: .none,
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
                  shape: .circle,
                ),
                alignment: .center,
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: .w700,
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
