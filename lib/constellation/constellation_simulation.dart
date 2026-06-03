import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'constellation_simulation_web.dart';

class ConstellationNode {
  final String id;
  final String? assignedTo;

  const ConstellationNode({required this.id, this.assignedTo});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConstellationNode &&
          id == other.id &&
          assignedTo == other.assignedTo;

  @override
  int get hashCode => Object.hash(id, assignedTo);
}

class ConstellationEdge {
  final String source;
  final String target;

  const ConstellationEdge({required this.source, required this.target});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConstellationEdge &&
          source == other.source &&
          target == other.target;

  @override
  int get hashCode => Object.hash(source, target);
}

abstract class ConstellationSimulation {
  /// Fires on every sim tick with updated world-space positions (origin-centered).
  ValueNotifier<Map<String, Offset>> get positions;

  /// Start the simulation. [viewport] is the size of the visible area, used to
  /// scatter fresh nodes across the screen instead of stacking them at the origin.
  Future<void> initialize({
    required List<ConstellationNode> nodes,
    required List<ConstellationEdge> edges,
    required Map<String, dynamic> forces,
    required Size viewport,
  });

  /// Reheat with new data, preserving existing positions (alpha 0.3).
  void update({
    required List<ConstellationNode> nodes,
    required List<ConstellationEdge> edges,
    required Map<String, dynamic> forces,
  });

  /// Pin a node at the given world position (called continuously during drag).
  void dragNode(String id, Offset worldPosition);

  /// Release a pinned node (called on pointer-up).
  void releaseNode(String id);

  void dispose();

  factory ConstellationSimulation() => createConstellationSimulation();
}
