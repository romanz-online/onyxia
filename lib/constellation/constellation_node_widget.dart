import 'package:onyxia/export.dart';

import 'constellation_simulation.dart';

/// The label portion of a node. Rendered in a separate Z-layer above all circles.
class ConstellationNodeLabel extends StatelessWidget {
  final ConstellationNode node;
  final double radius;
  final bool isHovered;
  final double labelOpacity;

  const ConstellationNodeLabel({
    super.key,
    required this.node,
    required this.radius,
    required this.isHovered,
    required this.labelOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isHovered
        ? ThemeHelper.foreground1()
        : ThemeHelper.foreground2();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isHovered ? 8.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, dy, child) =>
          Transform.translate(offset: Offset(0, dy), child: child),
      child: IgnorePointer(
        child: Opacity(
          opacity: labelOpacity,
          child: Text(
            node.id,
            style: TextStyle(fontSize: 11, color: labelColor),
            softWrap: false,
            overflow: .visible,
          ),
        ),
      ),
    );
  }
}
