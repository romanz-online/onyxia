import 'package:crdt_lf/crdt_lf.dart';

/// Implementation of the Fugue tree for collaborative text editing
class FugueTree<T> {
  FugueTree._({
    required Map<FugueElementID, FugueNodeTriple<T>> nodes,
    required FugueElementID rootID,
  })  : _nodes = nodes,
        _rootID = rootID;

  /// Initializes a new empty Fugue tree
  factory FugueTree.empty() {
    // Initialize the tree with a root node
    final rootID = FugueElementID.nullID();
    final rootNode = FugueNode<T>(
      id: rootID,
      value: null,
      parentID: FugueElementID.nullID(),
      side: FugueSide.left,
    );
    final nodes = {
      rootID: FugueNodeTriple<T>(
        node: rootNode,
        leftChildren: [],
        rightChildren: [],
      ),
    };

    return FugueTree._(
      nodes: nodes,
      rootID: rootID,
    );
  }

  /// Creates a tree from a JSON object
  factory FugueTree.fromJson(
    Map<String, dynamic> json,
  ) {
    // Add nodes from the JSON object
    final nodesJson = json['nodes'] as Map<String, dynamic>;
    final nodes = <FugueElementID, FugueNodeTriple<T>>{};

    for (final entry in nodesJson.entries) {
      final id = FugueElementID.parse(entry.key);
      final triple =
          FugueNodeTriple<T>.fromJson(entry.value as Map<String, dynamic>);
      nodes[id] = triple;
    }

    return FugueTree._(
      nodes: nodes,
      rootID: FugueElementID.nullID(),
    );
  }

  /// The nodes in the tree, indexed by ID
  final Map<FugueElementID, FugueNodeTriple<T>> _nodes;

  /// Root node ID
  final FugueElementID _rootID;

  /// Returns all non-deleted values in the correct order
  List<T> values() {
    return _traverse(_rootID, (node) => node.value);
  }

  /// Returns all non-deleted nodes in the correct order
  List<FugueValueNode<T>> nodes() {
    return _traverse(_rootID, (node) => node);
  }

  /// Traverses the tree starting from the specified node
  ///
  /// Visits the left children, then the node itself, then the right children.
  /// Collects the non-deleted values (different from `⊥`).
  ///
  /// Implemented iteratively with an explicit stack: on dart2js the per-char
  /// Fugue chain produced by a large insert would otherwise overflow the
  /// (small) JS call stack via deep recursion through right-children.
  List<K> _traverse<K>(
    FugueElementID startID,
    K Function(FugueValueNode<T> node) transform,
  ) {
    final result = <K>[];
    if (!_nodes.containsKey(startID)) return result;

    final stack = <_TraverseFrame>[_TraverseFrame(startID)];
    while (stack.isNotEmpty) {
      final frame = stack.last;
      final triple = _nodes[frame.nodeID];
      if (triple == null) {
        stack.removeLast();
        continue;
      }
      final left = triple.leftChildren;
      final right = triple.rightChildren;
      final selfStep = left.length;
      final endStep = selfStep + 1 + right.length;

      if (frame.step < selfStep) {
        final childID = left[frame.step];
        frame.step++;
        if (_nodes.containsKey(childID)) {
          stack.add(_TraverseFrame(childID));
        }
      } else if (frame.step == selfStep) {
        frame.step++;
        final value = triple.node.value;
        if (value != null) {
          result.add(
            transform(FugueValueNode(id: triple.node.id, value: value)),
          );
        }
      } else if (frame.step < endStep) {
        final childID = right[frame.step - selfStep - 1];
        frame.step++;
        if (_nodes.containsKey(childID)) {
          stack.add(_TraverseFrame(childID));
        }
      } else {
        stack.removeLast();
      }
    }
    return result;
  }

  /// Inserts a list of nodes into the tree at the specified index
  void iterableInsert(
    int index,
    Iterable<FugueValueNode<T>> nodes,
  ) {
    if (nodes.isEmpty) {
      return;
    }

    // Find the node at position index - 1 (or root node if index is 0)
    final leftOrigin =
        index == 0 ? FugueElementID.nullID() : findNodeAtPosition(index - 1);

    // Find the next node after leftOrigin
    final rightOrigin = findNextNode(leftOrigin);

    // Insert first node
    final firstNodeID = nodes.first.id;
    insert(
      newID: firstNodeID,
      value: nodes.first.value,
      leftOrigin: leftOrigin,
      rightOrigin: rightOrigin,
    );

    // Insert remaining nodes as right children of the previous node
    var previousID = firstNodeID;
    for (final value in nodes.skip(1)) {
      final newNodeID = value.id;
      insert(
        newID: newNodeID,
        value: value.value,
        leftOrigin: previousID,
        rightOrigin: rightOrigin,
      );
      previousID = newNodeID;
    }
  }

  /// Inserts a new [FugueNode] into the tree with [newID] and [value]
  ///
  /// [leftOrigin] is the node at position `index-1`
  ///
  /// [rightOrigin] node after [leftOrigin] in traversal order
  ///
  /// if [leftOrigin] exists and [rightOrigin] is a right child of [leftOrigin],
  /// the new node will be a left child of [rightOrigin]
  /// otherwise if [leftOrigin] exists, the new node will be a right child
  /// of [leftOrigin]
  /// otherwise, the new node will be a left child of [rightOrigin]
  void insert({
    required FugueElementID newID,
    required T value,
    required FugueElementID leftOrigin,
    required FugueElementID rightOrigin,
  }) {
    // Determine if the new node should be a left or right child
    FugueNode<T> newNode;

    if (!leftOrigin.isNull &&
        _nodes.containsKey(leftOrigin) &&
        !rightOrigin.isNull &&
        _nodes.containsKey(rightOrigin)) {
      // Check if rightOrigin is a right child of leftOrigin
      final leftOriginTriple = _nodes[leftOrigin]!;
      if (leftOriginTriple.rightChildren.contains(rightOrigin)) {
        // Insert as left child of rightOrigin to maintain order
        newNode = FugueNode<T>(
          id: newID,
          value: value,
          parentID: rightOrigin,
          side: FugueSide.left,
        );
      } else {
        // Insert as right child of leftOrigin
        newNode = FugueNode<T>(
          id: newID,
          value: value,
          parentID: leftOrigin,
          side: FugueSide.right,
        );
      }
    } else if (!leftOrigin.isNull && _nodes.containsKey(leftOrigin)) {
      // The new node will be a right child of leftOrigin
      newNode = FugueNode<T>(
        id: newID,
        value: value,
        parentID: leftOrigin,
        side: FugueSide.right,
      );
    } else if (!rightOrigin.isNull && _nodes.containsKey(rightOrigin)) {
      // The new node will be a left child of rightOrigin
      newNode = FugueNode<T>(
        id: newID,
        value: value,
        parentID: rightOrigin,
        side: FugueSide.left,
      );
    } else if (leftOrigin.isNull) {
      // If leftOrigin is null, the new node will be a right child of the root
      newNode = FugueNode<T>(
        id: newID,
        value: value,
        parentID: _rootID,
        side: FugueSide.right,
      );
    } else {
      // If neither leftOrigin nor rightOrigin exists, insert at the beginning
      newNode = FugueNode<T>(
        id: newID,
        value: value,
        parentID: _rootID,
        side: FugueSide.left,
      );
    }

    // Add the node to the tree
    _addNodeToTree(newNode);
  }

  /// Deletes a node from the tree (marks it as deleted, `⊥`)
  void delete(FugueElementID nodeID) {
    if (_nodes.containsKey(nodeID)) {
      _nodes[nodeID]!.node.value = null;
    }
  }

  /// Updates a [FugueNode] by deleting the old value and inserting a new one.
  void update({
    required FugueElementID nodeID,
    required FugueElementID newID,
    required T newValue,
  }) {
    // Check if the node exists and is not already deleted
    if (!_nodes.containsKey(nodeID) || _nodes[nodeID]!.node.isDeleted) {
      return;
    }

    final index = nodes().indexWhere((node) => node.id == nodeID);
    if (index == -1) return;

    delete(nodeID);

    iterableInsert(index, [
      FugueValueNode(id: newID, value: newValue),
    ]);
  }

  /// Adds a node to the tree
  void _addNodeToTree(FugueNode<T> node) {
    final parentID = node.parentID;

    if (_nodes.containsKey(node.id)) {
      if (_nodes[node.id]!.node.value != null) {
        throw DuplicateNodeException('Node already exists: ${node.id}');
      }
    }

    // Create a new triple for the node
    final nodeTriple = FugueNodeTriple<T>(
      node: node,
      leftChildren: [],
      rightChildren: [],
    );
    _nodes[node.id] = nodeTriple;

    // Update the parent's children list
    if (node.side == FugueSide.left) {
      _nodes[parentID]!.leftChildren.add(node.id);
    } else {
      _nodes[parentID]!.rightChildren.add(node.id);
    }
  }

  /// Finds the node at the specified position in the tree
  FugueElementID findNodeAtPosition(int position) {
    return _findNodeAtPositionRecursive(
      nodeID: _rootID,
      targetPos: position,
      currentPos: _CurrentPosition(-1),
    );
  }

  /// Iterative helper to find the node at the specified position. Walks the
  /// tree in the same left-children / self / right-children order as
  /// [_traverse], counting non-deleted nodes, and returns the id of the
  /// `targetPos`-th one. Uses an explicit stack for the same dart2js
  /// stack-budget reasons as [_traverse].
  FugueElementID _findNodeAtPositionRecursive({
    required FugueElementID nodeID,
    required int targetPos,
    required _CurrentPosition currentPos,
  }) {
    if (!_nodes.containsKey(nodeID)) return FugueElementID.nullID();

    final stack = <_TraverseFrame>[_TraverseFrame(nodeID)];
    while (stack.isNotEmpty) {
      final frame = stack.last;
      final triple = _nodes[frame.nodeID];
      if (triple == null) {
        stack.removeLast();
        continue;
      }
      final left = triple.leftChildren;
      final right = triple.rightChildren;
      final selfStep = left.length;
      final endStep = selfStep + 1 + right.length;

      if (frame.step < selfStep) {
        final childID = left[frame.step];
        frame.step++;
        if (_nodes.containsKey(childID)) {
          stack.add(_TraverseFrame(childID));
        }
      } else if (frame.step == selfStep) {
        frame.step++;
        if (triple.node.value != null) {
          currentPos.increment();
          if (currentPos.value == targetPos) {
            return frame.nodeID;
          }
        }
      } else if (frame.step < endStep) {
        final childID = right[frame.step - selfStep - 1];
        frame.step++;
        if (_nodes.containsKey(childID)) {
          stack.add(_TraverseFrame(childID));
        }
      } else {
        stack.removeLast();
      }
    }
    return FugueElementID.nullID();
  }

  /// Finds the next node after [nodeID] in the traversal
  FugueElementID findNextNode(FugueElementID nodeID) {
    if (!_nodes.containsKey(nodeID)) {
      return FugueElementID.nullID();
    }

    final nodeTriple = _nodes[nodeID]!;

    // 1. If it has right children, the next is the first right child
    if (nodeTriple.rightChildren.isNotEmpty) {
      return nodeTriple.rightChildren.first;
    }

    // 2. Otherwise, climb up the tree until finding a node that is a left child
    // and return its right sibling
    var current = nodeID;
    while (!current.isNull) {
      final currentNode = _nodes[current]!.node;
      if (currentNode.side == FugueSide.left) {
        // Find the right sibling
        final parent = currentNode.parentID;
        if (!_nodes.containsKey(parent)) {
          break;
        }

        final parentTriple = _nodes[parent]!;
        final rightSiblings = parentTriple.rightChildren;
        if (rightSiblings.isNotEmpty) {
          return rightSiblings.first;
        }
      }
      current = currentNode.parentID;
    }

    // 3. If no right sibling is found, return null
    return FugueElementID.nullID();
  }

  /// Serializes the tree to JSON format
  Map<String, dynamic> toJson() {
    final nodesJson = <String, dynamic>{};
    for (final entry in _nodes.entries) {
      nodesJson[entry.key.toString()] = entry.value.toJson();
    }

    return {
      'nodes': nodesJson,
    };
  }

  /// Returns a string representation of the tree for debugging
  @override
  String toString() {
    final buffer = StringBuffer()..writeln('Tree:');
    _buildTreeString(_rootID, 0, buffer);
    return buffer.toString();
  }

  /// Iterative helper to build the string representation of a node and its
  /// children. Same emission order as the original recursive version
  /// (self header → left children → "Right children:" label → right children),
  /// driven by an explicit stack so very deep trees don't blow the call stack.
  void _buildTreeString(FugueElementID nodeID, int depth, StringBuffer buffer) {
    if (!_nodes.containsKey(nodeID)) return;

    final stack = <_PrintFrame>[_PrintFrame(nodeID, depth)];
    while (stack.isNotEmpty) {
      final frame = stack.last;
      final triple = _nodes[frame.nodeID];
      if (triple == null) {
        stack.removeLast();
        continue;
      }
      final left = triple.leftChildren;
      final right = triple.rightChildren;
      final indent = '  ' * frame.depth;
      // Step layout:
      //  0                      → emit "<indent><node>" + "<indent> Left children:"
      //  [1 .. left.length]     → push left[step-1]
      //  left.length + 1        → emit "<indent> Right children:"
      //  [left.length+2 .. end] → push right[step - left.length - 2]
      //  end                    → pop
      final leftEnd = left.length;
      final rightLabel = leftEnd + 1;
      final rightEnd = rightLabel + right.length;

      if (frame.step == 0) {
        buffer
          ..writeln('$indent${triple.node}')
          ..writeln('$indent Left children:');
        frame.step++;
      } else if (frame.step <= leftEnd) {
        final childID = left[frame.step - 1];
        frame.step++;
        if (_nodes.containsKey(childID)) {
          stack.add(_PrintFrame(childID, frame.depth + 1));
        }
      } else if (frame.step == rightLabel) {
        buffer.writeln('$indent Right children:');
        frame.step++;
      } else if (frame.step <= rightEnd) {
        final childID = right[frame.step - rightLabel - 1];
        frame.step++;
        if (_nodes.containsKey(childID)) {
          stack.add(_PrintFrame(childID, frame.depth + 1));
        }
      } else {
        stack.removeLast();
      }
    }
  }
}

class _CurrentPosition {
  _CurrentPosition(this.value);

  int value;

  void increment() {
    value++;
  }
}

/// Frame for the iterative pre/in/post-order traversal used by
/// [FugueTree._traverse] and [FugueTree._findNodeAtPositionRecursive].
/// [step] advances through left children (0..leftLen-1), then self
/// (==leftLen), then right children, before the frame is popped.
class _TraverseFrame {
  _TraverseFrame(this.nodeID);
  final FugueElementID nodeID;
  int step = 0;
}

/// Frame for [FugueTree._buildTreeString]: also carries the indent depth
/// since the printout is hierarchical, not flat.
class _PrintFrame {
  _PrintFrame(this.nodeID, this.depth);
  final FugueElementID nodeID;
  final int depth;
  int step = 0;
}
