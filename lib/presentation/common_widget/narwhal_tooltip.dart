import 'package:onyxia/export.dart';

class NarwhalTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final Decoration? decoration;
  final bool preferBelow;
  final double verticalOffset;
  final EdgeInsetsGeometry margin;

  const NarwhalTooltip({
    super.key,
    required this.message,
    required this.child,
    this.decoration,
    this.preferBelow = false,
    this.verticalOffset = 0,
    this.margin = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      decoration: decoration,
      preferBelow: preferBelow,
      verticalOffset: verticalOffset,
      margin: margin,
      child: child,
    );
  }
}
