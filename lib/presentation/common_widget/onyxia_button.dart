import 'package:onyxia/export.dart';

class OnyxiaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const OnyxiaButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return IntrinsicWidth(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: .all(5),
              decoration: BoxDecoration(
                color: isHovered
                    ? ThemeHelper.neutral800(context)
                    : Colors.transparent,
                borderRadius: .circular(4),
              ),
              child: Padding(
                padding: .fromLTRB(1.5, 0, 1.5, 2),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: .w600,
                    color: ThemeHelper.neutral300(context),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
