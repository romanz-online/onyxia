import 'package:onyxia/export.dart';

class OnyxiaButton extends StatelessWidget {
  final String label;
  final bool isPressed;
  final VoidCallback? onPressed;
  final IconData? leftIcon;
  final IconData? rightIcon;

  const OnyxiaButton({
    super.key,
    required this.label,
    this.isPressed = false,
    this.onPressed,
    this.leftIcon,
    this.rightIcon,
  });

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, isHovered) {
        // TODO: intrinsicwidth leads to the button overflowing its container when the label is long. need this widget to check against its container to provide a max width
        return IntrinsicWidth(
          child: GestureDetector(
            onTap: onPressed,
            child: Container(
              padding: .all(5),
              decoration: BoxDecoration(
                color: isHovered || isPressed
                    ? ThemeHelper.background2()
                    : Colors.transparent,
                borderRadius: .circular(4),
              ),
              child: Row(
                spacing: 3,
                children: [
                  if (leftIcon != null)
                    Icon(leftIcon!, color: ThemeHelper.foreground2(), size: 15),

                  Padding(
                    padding: .symmetric(horizontal: 2),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: .w600,
                        color: ThemeHelper.foreground1(),
                      ),
                    ),
                  ),

                  if (rightIcon != null)
                    Icon(
                      rightIcon!,
                      color: ThemeHelper.foreground2(),
                      size: 15,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
