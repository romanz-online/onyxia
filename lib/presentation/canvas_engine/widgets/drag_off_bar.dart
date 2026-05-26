import 'package:onyxia/export.dart';

/// Data class to carry information during drag operations
class DragOffBarData {
  final ArtifactType type;

  const DragOffBarData({required this.type});
}

/// Configuration for a button in the DragOffBar
class DragOffBarButton {
  final IconData icon;
  final VoidCallback? onDragCompleted;
  final DragOffBarData? dragData;
  final Widget Function()? dragFeedbackBuilder;

  const DragOffBarButton({
    required this.icon,
    this.onDragCompleted,
    this.dragData,
    this.dragFeedbackBuilder,
  });
}

/// A flexible toolbar widget that supports both clickable and draggable buttons
class DragOffBar extends StatelessWidget {
  final List<DragOffBarButton?> buttons; // null entries act as separators
  final double iconSize;
  final double height;

  const DragOffBar({
    super.key,
    required this.buttons,
    this.iconSize = 30.0,
    this.height = 56.0,
  });

  BoxDecoration _getPanelDecoration(BuildContext context) {
    return BoxDecoration(
      color: ThemeHelper.neutral100(context),
      borderRadius: .circular(8),
      border: .all(color: ThemeHelper.neutral400(context), width: 1),
      boxShadow: [
        BoxShadow(
          color: ThemeHelper.neutral900(context).withValues(alpha: 0.1),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Widget _buildSeparator(BuildContext context) =>
      Container(width: 1, height: 24, color: ThemeHelper.neutral300(context));

  Widget _buildDefaultDragFeedback(
    BuildContext context,
    DragOffBarButton button,
  ) {
    return Material(
      elevation: 4,
      borderRadius: .circular(8),
      child: Container(
        width: defaultArtifactObjectDimensions.width,
        height: defaultArtifactObjectDimensions.height,
        decoration: BoxDecoration(
          color: ThemeHelper.neutral100(context),
          borderRadius: .circular(8),
          border: .all(color: ThemeHelper.neutral300(context), width: 2),
        ),
        child: Center(
          child: Icon(
            button.icon,
            size: 24,
            color: ThemeHelper.neutral500(context),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, DragOffBarButton button) {
    final buttonWidget = OnyxiaIconButton(icon: button.icon, size: iconSize);

    // If no drag data is provided, return just the button
    if (button.dragData == null) {
      return buttonWidget;
    }

    // Wrap button with Draggable
    return Draggable<DragOffBarData>(
      data: button.dragData!,
      feedback:
          button.dragFeedbackBuilder?.call() ??
          _buildDefaultDragFeedback(context, button),
      childWhenDragging: Opacity(opacity: 0.5, child: buttonWidget),
      onDragCompleted: button.onDragCompleted,
      child: buttonWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> buttonWidgets = [];

    for (int i = 0; i < buttons.length; i++) {
      final button = buttons[i];

      // Handle null values as dividers
      if (button == null) {
        if (buttonWidgets.isNotEmpty) {
          buttonWidgets.add(const Gap(8));
          buttonWidgets.add(_buildSeparator(context));
        }
        continue;
      }

      // Add spacing between buttons
      if (buttonWidgets.isNotEmpty) {
        buttonWidgets.add(const Gap(8));
      }

      buttonWidgets.add(_buildButton(context, button));
    }

    return Positioned.fill(
      bottom: 16,
      child: Align(
        alignment: .bottomCenter,
        child: Container(
          height: height,
          decoration: _getPanelDecoration(context),
          child: Padding(
            padding: .symmetric(horizontal: 10),
            child: Row(mainAxisSize: .min, children: buttonWidgets),
          ),
        ),
      ),
    );
  }
}
