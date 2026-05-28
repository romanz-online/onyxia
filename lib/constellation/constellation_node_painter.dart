import 'package:onyxia/export.dart';

import 'constellation_simulation.dart';

class ConstellationNodePainter extends NarwhalPainter {
  final Map<String, Offset> screenPositions;
  final Map<String, ConstellationNode> nodeData;
  final Map<String, double> radii;
  final String? hoverNodeId;

  ConstellationNodePainter({
    required BuildContext context,
    required this.screenPositions,
    required this.nodeData,
    required this.radii,
    required this.hoverNodeId,
  }) : super(context);

  @override
  void paint(Canvas canvas, Size size) {
    final bgColor = ThemeHelper.neutral900(context);
    final anyHover = hoverNodeId != null;
    final paint = Paint();

    for (final entry in screenPositions.entries) {
      final node = nodeData[entry.key];
      if (node == null) continue; // skip hub nodes

      final isHovered = entry.key == hoverNodeId;
      final r = (radii[entry.key] ?? 7.0) * (isHovered ? 1.075 : 1.0);
      final opacity = (anyHover && !isHovered) ? 0.5 : 0.9;
      final color = isHovered
          ? ThemeHelper.accentColor()
          : ThemeHelper.neutral400(context);

      canvas.drawCircle(entry.value, r, paint..color = bgColor);
      canvas.drawCircle(
        entry.value,
        r,
        paint..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationNodePainter old) =>
      !identical(screenPositions, old.screenPositions) ||
      !identical(nodeData, old.nodeData) ||
      !identical(radii, old.radii) ||
      hoverNodeId != old.hoverNodeId;
}
