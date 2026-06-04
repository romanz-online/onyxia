import 'dart:math' as math;

import 'package:onyxia/export.dart';

import 'constellation_edge_painter.dart';
import 'constellation_node_painter.dart';
import 'constellation_node_widget.dart';
import 'constellation_simulation.dart';

class ConstellationRenderer extends StatefulWidget {
  /// Physics nodes — may include virtual hub nodes for assignee mode.
  final List<ConstellationNode> physicsNodes;

  /// Physics edges — the links the simulation uses for force calculations.
  final List<ConstellationEdge> physicsEdges;

  /// Visual edges — always parent-child, drawn regardless of layout mode.
  final List<ConstellationEdge> visualEdges;

  final Map<String, dynamic> forces;
  final void Function(String nodeId) onNodeTap;

  const ConstellationRenderer({
    super.key,
    required this.physicsNodes,
    required this.physicsEdges,
    required this.visualEdges,
    required this.forces,
    required this.onNodeTap,
  });

  @override
  State<ConstellationRenderer> createState() => _ConstellationRendererState();
}

class _ConstellationRendererState extends State<ConstellationRenderer> {
  late ConstellationSimulation _simulation;

  // Viewport transform
  double _zoom = 1.0;
  Offset _pan = .zero;

  // Interaction state
  String? _dragNodeId;
  String? _hoverNodeId;

  // Scale gesture start state
  double? _scaleStartZoom;
  Offset? _scaleStartFocalWorld;

  // Tap detection — track movement during a drag to distinguish tap from drag
  Offset? _dragStartLocalPos;
  double _dragTotalMove = 0;

  // Precomputed per rebuild — keyed by id, contains only real (renderable) nodes
  Map<String, int> _degree = {};
  Map<String, ConstellationNode> _nodeData = {};
  Map<String, double> _radii = {};

  @override
  void initState() {
    super.initState();
    _simulation = ConstellationSimulation();
    _recomputeDegree();
    _nodeData = _buildNodeData();
    // Defer to after first layout so the render box has a size — used to
    // scatter nodes across the viewport instead of stacking them at the origin.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _simulation.initialize(
        nodes: widget.physicsNodes,
        edges: widget.physicsEdges,
        forces: widget.forces,
      );
    });
  }

  @override
  void didUpdateWidget(ConstellationRenderer old) {
    super.didUpdateWidget(old);
    final nodesChanged = !_listsEqual(widget.physicsNodes, old.physicsNodes);
    final edgesChanged = !_listsEqual(widget.physicsEdges, old.physicsEdges);
    final forcesChanged = widget.forces != old.forces;

    if (nodesChanged || edgesChanged || forcesChanged) {
      _recomputeDegree();
      _nodeData = _buildNodeData();
      _simulation.update(
        nodes: widget.physicsNodes,
        edges: widget.physicsEdges,
        forces: widget.forces,
      );
    }
  }

  @override
  void dispose() {
    _simulation.dispose();
    super.dispose();
  }

  bool _listsEqual<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Only real (non-hub) nodes — used for rendering and hit testing.
  Map<String, ConstellationNode> _buildNodeData() {
    return {
      for (final n in widget.physicsNodes)
        if (!n.id.startsWith('__hub__')) n.id: n,
    };
  }

  void _recomputeDegree() {
    final d = <String, int>{};
    for (final e in widget.visualEdges) {
      d[e.source] = (d[e.source] ?? 0) + 1;
      d[e.target] = (d[e.target] ?? 0) + 1;
    }
    _degree = d;
  }

  // ── Coordinate helpers ────────────────────────────────────────────────────

  Size? get _size => (context.findRenderObject() as RenderBox?)?.size;

  Offset _w2s(Offset world, Size size) => Offset(
    size.width / 2 + (world.dx + _pan.dx) * _zoom,
    size.height / 2 + (world.dy + _pan.dy) * _zoom,
  );

  Offset _s2w(Offset screen, Size size) => Offset(
    (screen.dx - size.width / 2) / _zoom - _pan.dx,
    (screen.dy - size.height / 2) / _zoom - _pan.dy,
  );

  double _nodeRadius(String id) {
    const base = 7.0;
    const maxMult = 1.85;
    final d = _degree[id] ?? 0;
    return base * math.min(1 + d * 0.035, maxMult);
  }

  String? _hitTest(Offset localPos, Size size, Map<String, Offset> positions) {
    for (final entry in positions.entries) {
      if (!_nodeData.containsKey(entry.key)) continue; // skip virtual hub nodes
      final sp = _w2s(entry.value, size);
      final r = _radii[entry.key] ?? _nodeRadius(entry.key);
      final hitR = math.max(r, 8.0);
      final dx = localPos.dx - sp.dx;
      final dy = localPos.dy - sp.dy;
      if (dx * dx + dy * dy < hitR * hitR) return entry.key;
    }
    return null;
  }

  // ── Gesture handlers ──────────────────────────────────────────────────────

  void _onScrollZoom(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final size = _size;
    if (size == null) return;

    final factor = event.scrollDelta.dy < 0 ? 1.1 : 0.9;
    final localPos = event.localPosition;
    final worldUnderMouse = _s2w(localPos, size);

    setState(() {
      _zoom = (_zoom * factor).clamp(0.05, 20.0);
      _pan = Offset(
        (localPos.dx - size.width / 2) / _zoom - worldUnderMouse.dx,
        (localPos.dy - size.height / 2) / _zoom - worldUnderMouse.dy,
      );
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    final size = _size;
    if (size == null) return;
    final localPos = details.localFocalPoint;
    _dragStartLocalPos = localPos;
    _dragTotalMove = 0;

    final positions = _simulation.positions.value;
    final hit = details.pointerCount == 1
        ? _hitTest(localPos, size, positions)
        : null;

    if (hit != null) {
      setState(() => _dragNodeId = hit);
      _simulation.dragNode(hit, _s2w(localPos, size));
    } else {
      _scaleStartZoom = _zoom;
      _scaleStartFocalWorld = _s2w(localPos, size);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final size = _size;
    if (size == null) return;
    final localPos = details.localFocalPoint;

    if (_dragNodeId != null) {
      if (_dragStartLocalPos != null) {
        _dragTotalMove = (localPos - _dragStartLocalPos!).distance;
      }
      _simulation.dragNode(_dragNodeId!, _s2w(localPos, size));
      return;
    }

    if (_scaleStartFocalWorld == null) return;

    final newZoom = (_scaleStartZoom! * details.scale).clamp(0.05, 20.0);
    setState(() {
      _zoom = newZoom;
      _pan = Offset(
        (localPos.dx - size.width / 2) / newZoom - _scaleStartFocalWorld!.dx,
        (localPos.dy - size.height / 2) / newZoom - _scaleStartFocalWorld!.dy,
      );
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_dragNodeId != null) {
      if (_dragTotalMove < 8.0) widget.onNodeTap(_dragNodeId!);
      _simulation.releaseNode(_dragNodeId!);
      setState(() => _dragNodeId = null);
    }
    _dragStartLocalPos = null;
    _dragTotalMove = 0;
    _scaleStartZoom = null;
    _scaleStartFocalWorld = null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Recomputes only on setState (hover/pan/zoom) or didUpdateWidget (data change),
    // NOT on every physics tick (which only rebuilds inside ValueListenableBuilder).
    _radii = {for (final id in _nodeData.keys) id: _nodeRadius(id)};

    return Material(
      type: .transparency,
      clipBehavior: .antiAlias,
      child: ValueListenableBuilder<Map<String, Offset>>(
        valueListenable: _simulation.positions,
        builder: (context, worldPositions, _) {
          return MouseRegion(
            onHover: (event) {
              final size = _size;
              if (size == null) return;
              final hit = _hitTest(
                event.localPosition,
                size,
                _simulation.positions.value,
              );
              if (hit != _hoverNodeId) setState(() => _hoverNodeId = hit);
            },
            onExit: (_) {
              if (_hoverNodeId != null) setState(() => _hoverNodeId = null);
            },
            cursor: MouseCursor.defer,
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: Listener(
                onPointerSignal: _onScrollZoom,
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final physicsIds = {
                      for (final n in widget.physicsNodes) n.id,
                    };
                    final screenPos = {
                      for (final e in worldPositions.entries)
                        if (physicsIds.contains(e.key))
                          e.key: _w2s(e.value, constraints.biggest),
                    };
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        RepaintBoundary(
                          child: NarwhalPaint(
                            painter: ConstellationEdgePainter(
                              screenPositions: screenPos,
                              edges: widget.visualEdges,
                              hoverNodeId: _hoverNodeId,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        RepaintBoundary(
                          child: NarwhalPaint(
                            painter: ConstellationNodePainter(
                              context: ctx,
                              screenPositions: screenPos,
                              nodeData: _nodeData,
                              radii: _radii,
                              hoverNodeId: _hoverNodeId,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        // labels (above all circles)
                        for (final entry in screenPos.entries)
                          if (_nodeData.containsKey(entry.key))
                            Positioned(
                              key: ValueKey('label_${entry.key}'),
                              left: entry.value.dx - _radii[entry.key]! - 2,
                              top: entry.value.dy + _radii[entry.key]! + 4,
                              child: ConstellationNodeLabel(
                                node: _nodeData[entry.key]!,
                                radius: _radii[entry.key]!,
                                isHovered: _hoverNodeId == entry.key,
                                labelOpacity: _hoverNodeId == entry.key
                                    ? 1.0
                                    : ((_zoom - 0.4) / (0.7 - 0.4)).clamp(
                                        0.0,
                                        1.0,
                                      ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
