import 'package:onyxia/export.dart';

/// A simplified button component for subsections that only supports text labels
/// @ponder ponder/NarwhalSubSectionButton.gif
class NarwhalSubSectionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isSelected;
  final double? width;
  final double? height;

  const NarwhalSubSectionButton({
    super.key,
    required this.text,
    this.onTap,
    this.isSelected = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper.subSectionButton;

    Color getBackgroundColor(Set<WidgetState> states) {
      if (isSelected) {
        return theme.selectedBackgroundColor(context);
      } else if (states.contains(WidgetState.pressed)) {
        return theme.pressedBackgroundColor(context);
      } else if (states.contains(WidgetState.hovered)) {
        return theme.hoveredBackgroundColor(context);
      } else {
        return theme.defaultBackgroundColor(context);
      }
    }

    Color getForegroundColor() => theme.textColor(context);

    final button = OutlinedButton(
      onPressed: onTap,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color>(getBackgroundColor),
        foregroundColor: WidgetStateProperty.all(getForegroundColor()),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        side: WidgetStateProperty.all(BorderSide.none),
      ),
      child: Text(
        text,
        style: NarwhalTextStyle.titleMedium(
          fontSize: 14,
          height: -0.1,
        ),
      ),
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
