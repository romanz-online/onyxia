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

  Color getIconColor() {
    Color result = ThemeHelper.foreground1();
    return enabled ? result : result.withValues(alpha: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    Color getBackgroundColor(Set<WidgetState> states) {
      if (!enabled) {
        return Colors.transparent;
      } else if (isPressed || states.contains(WidgetState.pressed)) {
        return ThemeHelper.auxiliary().withValues(alpha: 0.5);
      } else if (isSelected) {
        return ThemeHelper.auxiliary().withValues(alpha: 0.8);
      } else if (states.contains(WidgetState.hovered)) {
        return ThemeHelper.background2();
      } else {
        // TODO: instead of changing background color explicitly like this, i want to see if it's possible to inherit the parent container's color automatically and lerp it color as needed so that the button always fits into the parent context WITHOUT explicitly passing in the parent's color as a parameter
        return Colors.transparent;
      }
    }

    final iconColorFinal = iconColor ?? getIconColor();

    final button = SizedBox(
      width: size + (hasCaret ? 24 : 0),
      height: size,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: ButtonStyle(
          padding: .all(.all(3)),
          backgroundColor: .resolveWith<Color>(getBackgroundColor),
          overlayColor: .all(Colors.transparent),
          side: .all(.none),
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
                    color: getIconColor(),
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
                  color: badgeColor ?? ThemeHelper.accent(),
                  shape: .circle,
                ),
                alignment: .center,
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: .w700,
                    color: ThemeHelper.foreground1(),
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
