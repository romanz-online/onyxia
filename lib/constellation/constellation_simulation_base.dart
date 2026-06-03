import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'constellation_simulation.dart';

/// Shared state and logic for both web and native simulation implementations.
/// Subclasses provide only the platform-specific transport (Worker / Isolate)
/// by implementing [dispatch].
///
/// The simulation is a pure physics runner — it knows nothing about layout
/// modes. All layout decisions (which nodes/edges/forces to pass) live in
/// the caller (constellation.dart).
/// Exposes [notifyListeners] so simulation classes can fire listeners after
/// mutating [value] in-place, without allocating a new Map each tick.
class ConstellationPositionNotifier extends ValueNotifier<Map<String, Offset>> {
  ConstellationPositionNotifier(super.value);
  void ping() => notifyListeners();
}

abstract class ConstellationSimulationBase implements ConstellationSimulation {
  /// Cached world-space positions for all nodes (real + any virtual nodes).
  /// Also the live backing store for [positions] — mutated in-place each tick.
  final current = <String, Offset>{};

  @override
  late final ConstellationPositionNotifier positions;

  ConstellationSimulationBase() {
    positions = ConstellationPositionNotifier(current);
  }

  final _rng = math.Random();

  /// Visible viewport size, used to scatter fresh nodes across the screen.
  /// Null until [setViewport] is called (e.g. an update arriving before the
  /// first layout); falls back to a tiny origin cluster in that case.
  Size? _viewport;

  /// Inset from the viewport edges so nodes never spawn flush against the border.
  static const _spreadMargin = 48.0;

  /// Records the visible area so [buildNodeMap] can scatter un-positioned nodes.
  @protected
  set viewport(Size size) => _viewport = size;

  // ── Abstract transport ────────────────────────────────────────────────────

  /// Send a message to the physics engine. Implemented by each platform.
  void dispatch(Map<String, dynamic> msg);

  // ── Shared public API ─────────────────────────────────────────────────────

  @override
  void update({
    required List<ConstellationNode> nodes,
    required List<ConstellationEdge> edges,
    required Map<String, dynamic> forces,
  }) {
    sendGraph(nodes, edges, forces: forces, alpha: 0.3);
  }

  @override
  void dragNode(String id, Offset worldPosition) {
    dispatch({
      'alpha': 0.3,
      'alphaTarget': 0.3,
      'run': true,
      'forceNode': {'id': id, 'x': worldPosition.dx, 'y': worldPosition.dy},
    });
  }

  @override
  void releaseNode(String id) {
    dispatch({
      'alphaTarget': 0.0,
      'forceNode': {'id': id, 'x': null, 'y': null},
    });
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  /// Builds the simulation payload and dispatches it.
  void sendGraph(
    List<ConstellationNode> nodes,
    List<ConstellationEdge> edges, {
    required Map<String, dynamic> forces,
    required double alpha,
  }) {
    dispatch({
      'nodes': buildNodeMap(nodes),
      'links': edges.map((e) => [e.source, e.target]).toList(),
      'forces': forces,
      'alpha': alpha,
      'run': true,
    });
  }

  /// Returns the cached or freshly-randomised position map for [nodes].
  Map<String, List<double>> buildNodeMap(List<ConstellationNode> nodes) {
    final result = <String, List<double>>{};
    for (final n in nodes) {
      final pos = current[n.id];
      if (pos != null) {
        result[n.id] = [pos.dx, pos.dy];
      } else {
        final double x, y;
        final viewport = _viewport;
        if (viewport != null) {
          // Scatter uniformly across the visible rectangle (world space is
          // screen-centered at the default zoom/pan), inset by a margin.
          final spreadW = math.max(0.0, viewport.width - 2 * _spreadMargin);
          final spreadH = math.max(0.0, viewport.height - 2 * _spreadMargin);
          x = (_rng.nextDouble() - 0.5) * spreadW;
          y = (_rng.nextDouble() - 0.5) * spreadH;
        } else {
          // No viewport yet — fall back to a tiny origin cluster.
          final a = _rng.nextDouble() * math.pi * 2;
          final d = _rng.nextDouble() * 5;
          x = math.cos(a) * d;
          y = math.sin(a) * d;
        }
        current[n.id] = Offset(x, y);
        result[n.id] = [x, y];
      }
    }
    return result;
  }
}
