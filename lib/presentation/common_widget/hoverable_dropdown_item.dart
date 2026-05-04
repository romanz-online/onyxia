import 'package:onyxia/export.dart';

class HoverableDropdownItem extends StatefulWidget {
  final String text;
  final Color? textColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const HoverableDropdownItem({
    super.key,
    required this.text,
    this.textColor,
    this.textStyle,
    this.padding,
  });

  @override
  State<HoverableDropdownItem> createState() => _HoverableDropdownItemState();
}

class _HoverableDropdownItemState extends State<HoverableDropdownItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: null,
      padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.text,
        overflow: TextOverflow.ellipsis,
        style: widget.textStyle ??
            NarwhalTextStyle(
              color: widget.textColor ?? ThemeHelper.black(context).withValues(alpha: 0.87),
            ),
      ),
    );
  }
}
