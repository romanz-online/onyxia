import 'package:flutter/cupertino.dart';
import 'package:touchable/src/shapes/clip.dart';
import 'package:touchable/src/shapes/shape.dart';
import 'package:touchable/src/shapes/util.dart';
import 'package:touchable/src/types/types.dart';

// Note: CanvasInteractionContext mapping is handled via the _shapeToContextMap

class ShapeHandler {
  final List<Shape> _shapeStack = [];
  final List<ClipShapeItem> clipItems = [];
  final Set<GestureType> _registeredGestures = {};
  final Set<Shape> _hoveredShapes = {};
  final Map<Shape, dynamic> _shapeToContextMap = {};

  Set<GestureType> get registeredGestures => _registeredGestures;

  void addShape(Shape shape, [dynamic interactionContext]) {
    if (shape is ClipShape) {
      clipItems.add(ClipShapeItem(shape, _shapeStack.length));
    } else {
      _shapeStack.add(shape);
      _registeredGestures.addAll(shape.registeredGestures);
      
      // Store shape-to-context mapping if context is provided
      if (interactionContext != null) {
        _shapeToContextMap[shape] = interactionContext;
      }
    }
  }

  /// Get the CanvasInteractionContext associated with a shape
  dynamic getContextForShape(Shape shape) {
    return _shapeToContextMap[shape];
  }

  /// STK   CLIPSTK
  ///| 3 |
  /// push clip --->
  ///| 2 |        |   |
  ///| 1 |        |   |
  ///|_0_|        |_3_|
  ///
  /// Looking at above diagram , given the stack position 3 , this function returns all ClipShapes that are pushed before 3 into the clip stack.
  List<ClipShape> _getClipShapesBelowPosition(int position) {
    return clipItems.where((element) => element.position <= position).map((e) => e.clipShape).toList();
  }

  ///returns [true] if point lies inside all the clipShapes
  bool _isPointInsideClipShapes(List<ClipShape> clipShapes, Offset point) {
    for (int i = 0; i < clipShapes.length; i++) {
      if (!clipShapes[i].isInside(point)) return false;
    }
    return true;
  }

  Offset _getActualOffsetFromScrollController(
      Offset touchPoint, ScrollController? controller, AxisDirection direction) {
    if (controller == null) {
      return touchPoint;
    }

    final scrollPosition = controller.position;
    final actualScrollPixels = direction == AxisDirection.left || direction == AxisDirection.up
        ? scrollPosition.maxScrollExtent - scrollPosition.pixels
        : scrollPosition.pixels;

    if (direction == AxisDirection.left || direction == AxisDirection.right) {
      return Offset(touchPoint.dx + actualScrollPixels, touchPoint.dy);
    } else {
      return Offset(touchPoint.dx, touchPoint.dy + actualScrollPixels);
    }
  }

  List<Shape> getTouchedShapes(Offset point) {
    var selectedShapes = <Shape>[];
    for (int i = _shapeStack.length - 1; i >= 0; i--) {
      var shape = _shapeStack[i];
      if (shape.hitTestBehavior == HitTestBehavior.deferToChild) {
        continue;
      }
      if (shape.isInside(point)) {
        if (_isPointInsideClipShapes(_getClipShapesBelowPosition(i), point) == false) {
          if (shape.hitTestBehavior == HitTestBehavior.opaque) {
            return selectedShapes;
          }
          continue;
        }
        selectedShapes.add(shape);
        if (shape.hitTestBehavior == HitTestBehavior.opaque) {
          return selectedShapes;
        }
      }
    }
    return selectedShapes;
  }

  Future<void> handleGestureEvent(
    Gesture gesture, {
    ScrollController? scrollController,
    AxisDirection direction = AxisDirection.down,
  }) async {
    var touchPoint = _getActualOffsetFromScrollController(
        TouchCanvasUtil.getPointFromGestureDetail(gesture.gestureDetail), scrollController, direction);
    if (!_registeredGestures.contains(gesture.gestureType)) return;

    // Handle hover events specially for enter/exit logic
    if (gesture.gestureType == GestureType.onHover) {
      await _handleHoverEvent(touchPoint, gesture);
      return;
    }

    var touchedShapes = getTouchedShapes(touchPoint);
    if (touchedShapes.isEmpty) return;
    for (var touchedShape in touchedShapes) {
      if (touchedShape.registeredGestures.contains(gesture.gestureType)) {
        var callback = touchedShape.getCallbackFromGesture(gesture);
        callback();
      }
    }
  }

  Future<void> _handleHoverEvent(Offset touchPoint, Gesture hoverGesture) async {
    var currentTouchedShapes = getTouchedShapes(touchPoint);
    var newHovered = currentTouchedShapes.toSet();

    // Temporarily disabled - onExit processing
    // var exited = _hoveredShapes.difference(newHovered);
    // for (var shape in exited) {
    //   if (shape.registeredGestures.contains(GestureType.onExit)) {
    //     var exitGesture = Gesture(GestureType.onExit, hoverGesture.gestureDetail);
    //     var callback = shape.getCallbackFromGesture(exitGesture);
    //     callback();
    //   }
    // }

    // Temporarily disabled - onEnter processing
    // var entered = newHovered.difference(_hoveredShapes);
    // for (var shape in entered) {
    //   if (shape.registeredGestures.contains(GestureType.onEnter)) {
    //     var enterGesture = Gesture(GestureType.onEnter, hoverGesture.gestureDetail);
    //     var callback = shape.getCallbackFromGesture(enterGesture);
    //     callback();
    //   }
    // }

    // Trigger onHover for all currently hovered shapes
    for (var shape in newHovered) {
      if (shape.registeredGestures.contains(GestureType.onHover)) {
        var callback = shape.getCallbackFromGesture(hoverGesture);
        callback();
      }
    }

    _hoveredShapes.clear();
    _hoveredShapes.addAll(newHovered);
  }
}
