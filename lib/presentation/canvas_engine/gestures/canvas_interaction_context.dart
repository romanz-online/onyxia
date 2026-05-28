import 'package:onyxia/export.dart';

/// Sealed class hierarchy for tracking what canvas element was interacted with
/// Provides type-safe distinction between background, canvas objects, and UI controls
sealed class CanvasInteractionContext {
  const CanvasInteractionContext();
}

class BackgroundInteraction extends CanvasInteractionContext {
  const BackgroundInteraction();

  @override
  String toString() => 'BackgroundInteraction';
}

/// Represents interaction with an arrow well UI control
class ArrowWellInteraction extends CanvasInteractionContext {
  final CanvasObject sourceObject;
  final ConnectionPoint connectionPoint;

  const ArrowWellInteraction({
    required this.sourceObject,
    required this.connectionPoint,
  });
}

/// Represents interaction with an arrow text area widget
class ArrowTextInteraction extends CanvasInteractionContext {
  final CanvasObject targetObject;

  const ArrowTextInteraction({required this.targetObject});
}

/// Represents interaction with a canvas object resize handle
class ObjectResizeInteraction extends CanvasInteractionContext {
  final CanvasObject targetObject;
  final ResizeHandle handle;

  const ObjectResizeInteraction({
    required this.targetObject,
    required this.handle,
  });
}

/// Represents interaction with an arrow segment resize handle
class ArrowResizeInteraction extends CanvasInteractionContext {
  final CanvasObject targetObject;
  final int segmentIndex;

  const ArrowResizeInteraction({
    required this.targetObject,
    required this.segmentIndex,
  });
}

/// Enum for specifying which arrow endpoint to move
enum ArrowMoveType { start, end, none }

/// Represents interaction with an arrow move handle (start or end)
class ArrowMoveInteraction extends CanvasInteractionContext {
  final CanvasObject targetObject;
  final ArrowMoveType moveType;

  const ArrowMoveInteraction({
    required this.targetObject,
    required this.moveType,
  });
}

/// Represents interaction with an arrow tool well in arrow tool mode
class ArrowToolWellInteraction extends CanvasInteractionContext {
  final CanvasObject sourceObject;
  final Offset startOffset;
  final ConnectionPoint closestEdge;

  const ArrowToolWellInteraction({
    required this.sourceObject,
    required this.startOffset,
    required this.closestEdge,
  });
}

/// Represents interaction with a canvas object itself (tap, click)
class ObjectFillInteractionContext extends CanvasInteractionContext {
  final CanvasObject targetObject;
  final String? shapeType;

  const ObjectFillInteractionContext({
    required this.targetObject,
    this.shapeType,
  });

  @override
  String toString() =>
      'ObjectInteractionContext(objectId: ${targetObject.id}, shapeType: $shapeType)';
}
