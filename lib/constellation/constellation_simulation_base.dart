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
        // TODO: be a little smarter here. determine where the biggest cluster of nodes is, place it scattered near the center, then place the rest of the nodes around the edges, ideally also clustered among themselves. basically precompute a little bit of the physics result beforehand, not fully.
        final a = _rng.nextDouble() * math.pi * 2;
        final d = _rng.nextDouble() * 5;
        final x = math.cos(a) * d * 50;
        final y = math.sin(a) * d * 50;
        current[n.id] = Offset(x, y);
        result[n.id] = [x, y];
      }
    }
    return result;
  }
}
