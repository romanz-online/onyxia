import 'package:onyxia/export.dart';

import 'constellation_simulation.dart';

/// Draws only the edges between nodes. Receives pre-computed screen-space
/// positions so it needs no zoom/pan transform of its own.
class ConstellationEdgePainter extends CustomPainter {
  final Map<String, Offset> screenPositions;
  final List<ConstellationEdge> edges;
  final String? hoverNodeId;

  const ConstellationEdgePainter({
    required this.screenPositions,
    required this.edges,
    this.hoverNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hasHover = hoverNodeId != null;
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final edge in edges) {
      final a = screenPositions[edge.source];
      final b = screenPositions[edge.target];
      if (a == null || b == null) continue;

      final isConnected = hasHover && (edge.source == hoverNodeId || edge.target == hoverNodeId);

      edgePaint.color = hasHover
          ? (isConnected ? ThemeHelper.accentColor() : const Color(0x1E969696) /* rgba(150,150,150, 0.12) */)
          : const Color(0x59969696); // rgba(150,150,150, 0.35)

      canvas.drawLine(a, b, edgePaint);
    }
  }

  @override
  bool shouldRepaint(ConstellationEdgePainter old) =>
      !identical(screenPositions, old.screenPositions) ||
      hoverNodeId != old.hoverNodeId ||
      !identical(edges, old.edges);
}
