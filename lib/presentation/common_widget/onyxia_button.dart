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
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isHovered ? ThemeHelper.neutral200(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(1.5, 0, 1.5, 2),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NarwhalTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.neutral700(context),
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
