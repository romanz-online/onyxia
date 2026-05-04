import 'package:onyxia/export.dart';

class NarwhalModalInputDecoration {
  static InputDecoration create(BuildContext context, {required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: NarwhalTextStyle(
        color: ThemeHelper.neutral500(context).withValues(alpha: 0.7),
      ),
      counter: const SizedBox(),
      fillColor: ThemeHelper.neutral100(context),
      filled: true,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: ThemeHelper.neutral400(context), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: ThemeHelper.blue500(context), width: 1),
      ),
    );
  }
}

/// A reusable modal dialog widget with title, content, and action buttons
class NarwhalModalDialog extends ConsumerStatefulWidget {
  final String title;
  final Widget? content;
  final String actionButtonText;
  final String? cancelButtonText;
  final VoidCallback? onActionPressed;
  final bool onActionEnabled;
  final VoidCallback? onCancelPressed;
  final double? width;
  final double? height;
  final bool isDestructive;
  final bool hasLargeTitle;
  final List<Widget>? additionalLeftActions;

  const NarwhalModalDialog({
    super.key,
    required this.title,
    required this.actionButtonText,
    this.onActionPressed,
    this.onActionEnabled = true,
    this.content,
    this.cancelButtonText = "Cancel",
    this.onCancelPressed,
    this.width = 500.0,
    this.height = 300.0,
    this.isDestructive = false,
    this.hasLargeTitle = false,
    this.additionalLeftActions,
  });

  @override
  ConsumerState<NarwhalModalDialog> createState() => _NarwhalModalDialogState();
}

class _NarwhalModalDialogState extends ConsumerState<NarwhalModalDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        constraints: const BoxConstraints(
          minWidth: 300,
        ),
        decoration: BoxDecoration(
          color: ThemeHelper.neutral100(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: BoxDecoration(
                color: ThemeHelper.neutral100(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: widget.hasLargeTitle
                        ? NarwhalStyles.modalLargeTitleStyle(context)
                        : NarwhalStyles.modalTitleStyle(context),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.content != null ? widget.content! : SizedBox(),

                    const Spacer(flex: 1),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side actions
                        if (widget.additionalLeftActions != null)
                          Row(
                            children: widget.additionalLeftActions!,
                          ),
                        if (widget.additionalLeftActions == null) SizedBox(), // Empty spacer when no left actions
                        // Right side actions
                        Row(
                          children: [
                            if (widget.cancelButtonText != null) ...[
                              NarwhalButton(
                                text: widget.cancelButtonText!,
                                type: NarwhalButtonType.secondary,
                                onTap: widget.onCancelPressed ??
                                    () {
                                      Navigator.of(context).pop();
                                    },
                              ),
                              const SizedBox(width: 20),
                            ],
                            NarwhalButton(
                              text: widget.actionButtonText,
                              type: NarwhalButtonType.secondary,
                              onTap: widget.onActionPressed,
                              enabled: widget.onActionEnabled,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
