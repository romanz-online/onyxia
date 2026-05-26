import 'dart:math';
import 'package:onyxia/export.dart';
import 'package:touchable/touchable.dart';
import '../../gestures/gestures.dart';
import '../../providers/providers.dart';
import 'canvas_object_painter.dart';
import 'touchy_object_painter.dart';
import 'arrow_point_painter.dart';

class CanvasPainter extends NarwhalPainter {
  final WidgetRef ref;
  final CanvasGestureRouter? gestureRouter;
  final List<CanvasObject> objects;
  final List<CanvasObject> selectedObjects;
  final List<CanvasObject> draggedObjects;
  final List<CanvasObject> arrowPrimedObjects;
  final Rect? dragSelect;
  final String? textEditedObjId;
  final String? potentialDropTargetId;
  final ArrowPreview? arrowPreview;
  final ArrowToolPrimedData? arrowToolPrimedData;
  final bool isInteractive;

  // Store TouchyCanvas reference for external hit testing
  TouchyCanvas? _touchyCanvas;

  CanvasPainter({
    required this.ref,
    required BuildContext context,
    this.gestureRouter,
    this.objects = const <CanvasObject>[],
    this.selectedObjects = const <CanvasObject>[],
    this.draggedObjects = const <CanvasObject>[],
    this.arrowPrimedObjects = const <CanvasObject>[],
    this.dragSelect,
    this.textEditedObjId,
    this.potentialDropTargetId,
    this.arrowPreview,
    this.arrowToolPrimedData,
    this.isInteractive = true,
  }) : super(context);

  @override
  void paint(Canvas canvas, Size size) {
    final touchyCanvas = TouchyCanvas(context, canvas);
    _touchyCanvas = touchyCanvas; // Store for external hit testing

    // Add background gesture detection first (if gesture router is available)
    if (gestureRouter != null) {
      TouchyObjectPainter(
        touchyCanvas,
        gestureRouter: gestureRouter,
        interactionContext: const BackgroundInteraction(),
        isInteractive: isInteractive,
      ).drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.transparent,
      );
    }

    _drawCanvasObjects(touchyCanvas, canvas);
    _drawSelectionHighlights(touchyCanvas, canvas);
    _drawArrowToolWell(touchyCanvas, canvas);
    paintDragSelect(context, canvas, dragSelect);
    _drawAlignment(canvas);

    // Draw arrow preview if available
    if (arrowPreview != null) {
      _drawArrowPreview(touchyCanvas, canvas, arrowPreview!);
    }

    // Draw headless arrow ghost object if available
    final paletteState = ref.read(headlessProvider);
    if (paletteState.hasGhostObject) {
      CanvasObjectPainter.paint(
        touchyCanvas,
        canvas,
        paletteState.ghostObject!,
        context,
        ref,
        isGhost: true,
        gestureRouter: gestureRouter,
        interactionContext: ObjectFillInteractionContext(
          targetObject: paletteState.ghostObject!,
        ),
        isInteractive: isInteractive,
      );
    }
  }

  /// Hit test for external drop events - returns the interaction context of the hit shape
  /// Returns null if no object is hit or if TouchyCanvas is not available
  dynamic hitTestForDropEvent(Offset point) {
    if (_touchyCanvas == null) return null;
    return _touchyCanvas!.hitTestForDropEvent(point);
  }

  void _drawCanvasObjects(TouchyCanvas touchyCanvas, Canvas canvas) {
    final scale = ref.read(canvasViewportProvider).value.getMaxScaleOnAxis();
    final gestureState = ref.watch(canvasGestureStateProvider);
    final activeObject = gestureState.activeObject;
    final ArrowMoveType moveType = gestureState.arrowMoveType;
    final toolMode = ref.watch(toolModeProvider);
    final arrowToolPrimedData = ref.watch(arrowToolPrimedObjectsProvider);

    for (final object in objects) {
      // Calculate if this object should have gaps drawn
      final bool drawGaps =
          (activeObject != null &&
              activeObject.isArrow &&
              ((moveType == ArrowMoveType.start &&
                      activeObject.arrowProps.startObjectId == object.id) ||
                  (moveType == ArrowMoveType.end &&
                      activeObject.arrowProps.endObjectId == object.id))) ||
          (toolMode == ToolMode.arrow &&
              arrowToolPrimedData?.object.id == object.id);

      CanvasObjectPainter.paint(
        touchyCanvas,
        canvas,
        object,
        context,
        ref,
        drawGaps: drawGaps,
        gapLength: 14.0 / scale,
        gestureRouter: gestureRouter,
        interactionContext: ObjectFillInteractionContext(targetObject: object),
        isInteractive: isInteractive,
      );
    }
  }

  void _drawSelectionHighlights(TouchyCanvas touchyCanvas, Canvas canvas) {
    for (final object in selectedObjects) {
      if (object.isBrush) {
        final highlightPaint = Paint()
          ..color = ThemeHelper.blue500(context)
          ..style = .stroke
          ..strokeWidth = 1.5;

        canvas.drawRect(
          Rect.fromPoints(object.topLeft, object.bottomRight),
          highlightPaint,
        );
      }

      if (!object.isBrush &&
          !object.isArrow &&
          object.type != CanvasObjectType.text &&
          textEditedObjId != object.id) {
        _drawResizeEdges(touchyCanvas, canvas, object);
        _drawResizeCorners(touchyCanvas, canvas, object);
      }

      if (object.isArrow) {
        _drawArrowResizeHandles(touchyCanvas, canvas, object);
        _drawArrowMoveHandles(touchyCanvas, object);
      }
    }
  }

  void _drawAlignment(Canvas canvas) {
    final paint = Paint()
      ..color = ThemeHelper.accentColor()
      ..strokeWidth = 1.0
      ..style = .stroke;

    for (final draggedObject in draggedObjects.where((o) => !o.isArrow)) {
      for (final object in objects.where((o) => !o.isArrow)) {
        if (draggedObjects.contains(object)) continue;

        final draggedTL = draggedObject.topLeft;
        final draggedBR = draggedObject.bottomRight;
        final objectTL = object.topLeft;
        final objectBR = object.bottomRight;

        bool drawn = false;

        // Check for horizontal alignments (same Y coordinates)

        // TopLeft Y alignment (top edges align)
        // and
        // TopLeft-BottomRight Y alignment (top of dragged aligns with bottom of object)
        if (draggedTL.dy == objectTL.dy || draggedTL.dy == objectBR.dy) {
          final y = draggedTL.dy;
          final startX = min(draggedTL.dx, objectTL.dx);
          final endX = max(draggedBR.dx, objectBR.dx);
          canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
          drawn = true;
        }

        // BottomRight Y alignment (bottom edges align)
        // and
        // BottomRight-TopLeft Y alignment (bottom of dragged aligns with top of object)
        if (draggedBR.dy == objectTL.dy || draggedBR.dy == objectBR.dy) {
          final y = draggedBR.dy;
          final startX = min(draggedTL.dx, objectTL.dx);
          final endX = max(draggedBR.dx, objectBR.dx);
          canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
          drawn = true;
        }

        // Check for vertical alignments (same X coordinates)

        // TopLeft X alignment (left edges align)
        // and
        // TopLeft-BottomRight X alignment (left of dragged aligns with right of object)
        if (draggedTL.dx == objectTL.dx || draggedTL.dx == objectBR.dx) {
          final x = draggedTL.dx;
          final startY = min(draggedTL.dy, objectTL.dy);
          final endY = max(draggedBR.dy, objectBR.dy);
          canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
          drawn = true;
        }

        // BottomRight X alignment (right edges align)
        // and
        // BottomRight-TopLeft X alignment (right of dragged aligns with left of object)
        if (draggedBR.dx == objectTL.dx || draggedBR.dx == objectBR.dx) {
          final x = draggedBR.dx;
          final startY = min(draggedTL.dy, objectTL.dy);
          final endY = max(draggedBR.dy, objectBR.dy);
          canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
          drawn = true;
        }

        if (!drawn) {
          final draggedCenterX = (draggedTL.dx + draggedBR.dx) / 2;
          final draggedCenterY = (draggedTL.dy + draggedBR.dy) / 2;
          final objectCenterX = (objectTL.dx + objectBR.dx) / 2;
          final objectCenterY = (objectTL.dy + objectBR.dy) / 2;

          // Center Y alignment (horizontal centers align)
          if (draggedCenterY == objectCenterY) {
            final y = draggedCenterY;
            final startX = min(draggedTL.dx, objectTL.dx);
            final endX = max(draggedBR.dx, objectBR.dx);
            canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
          }

          // Center X alignment (vertical centers align)
          if (draggedCenterX == objectCenterX) {
            final x = draggedCenterX;
            final startY = min(draggedTL.dy, objectTL.dy);
            final endY = max(draggedBR.dy, objectBR.dy);
            canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
          }
        }
      }
    }
  }

  void _drawArrowPreview(
    TouchyCanvas touchyCanvas,
    Canvas canvas,
    ArrowPreview preview,
  ) {
    final arrowInteractionContext = ObjectFillInteractionContext(
      targetObject: preview.arrow,
    );
    CanvasObjectPainter.paint(
      touchyCanvas,
      canvas,
      preview.arrow,
      context,
      ref,
      isGhost: true,
      gestureRouter: gestureRouter,
      interactionContext: arrowInteractionContext,
      isInteractive: isInteractive,
    );

    if (preview.hasGhostObject) {
      final ghostObject = preview.ghostObject!;
      final ghostInteractionContext = ObjectFillInteractionContext(
        targetObject: ghostObject,
      );
      CanvasObjectPainter.paint(
        touchyCanvas,
        canvas,
        ghostObject,
        context,
        ref,
        isGhost: true,
        gestureRouter: gestureRouter,
        interactionContext: ghostInteractionContext,
        isInteractive: isInteractive,
      );
    }
  }

  void _drawResizeEdges(
    TouchyCanvas touchyCanvas,
    Canvas canvas,
    CanvasObject object,
  ) {
    final scale = ref.read(canvasViewportProvider).value.getMaxScaleOnAxis();
    final edgeHandleThickness = 16.0 / scale;
    final edgeWidth = 1.5 / scale;

    final selectionColor = ThemeHelper.blue500(context);

    final edgeHandles = [
      ResizeHandle.topCenter,
      ResizeHandle.centerRight,
      ResizeHandle.bottomCenter,
      ResizeHandle.centerLeft,
    ];

    final objWidth = object.bottomRight.dx - object.topLeft.dx;
    final objHeight = object.bottomRight.dy - object.topLeft.dy;
    final topLeftPos = object.topLeft;
    final topRightPos = Offset(object.bottomRight.dx, object.topLeft.dy);
    final bottomLeftPos = Offset(object.topLeft.dx, object.bottomRight.dy);

    final visualFillPaint = Paint()
      ..color = selectionColor
      ..style = .fill;

    final hitBoxFillPaint = Paint()
      ..color = Colors.transparent
      ..style = .fill;

    for (final handle in edgeHandles) {
      final Rect handleRect = switch (handle) {
        ResizeHandle.topCenter => Rect.fromLTWH(
          topLeftPos.dx,
          topLeftPos.dy - edgeHandleThickness / 2,
          objWidth,
          edgeHandleThickness,
        ),
        ResizeHandle.centerRight => Rect.fromLTWH(
          topRightPos.dx - edgeHandleThickness / 2,
          topRightPos.dy,
          edgeHandleThickness,
          objHeight,
        ),
        ResizeHandle.bottomCenter => Rect.fromLTWH(
          bottomLeftPos.dx,
          bottomLeftPos.dy - edgeHandleThickness / 2,
          objWidth,
          edgeHandleThickness,
        ),
        ResizeHandle.centerLeft => Rect.fromLTWH(
          topLeftPos.dx - edgeHandleThickness / 2,
          topLeftPos.dy,
          edgeHandleThickness,
          objHeight,
        ),
        _ => Rect.zero,
      };

      if (handleRect == Rect.zero) continue;

      final isHorizontal =
          handle == ResizeHandle.centerLeft ||
          handle == ResizeHandle.centerRight;
      final lineHeight = isHorizontal ? handleRect.height : edgeWidth;
      final lineWidth = isHorizontal ? edgeWidth : handleRect.width;
      final lineRect = Rect.fromLTWH(
        handleRect.left + (handleRect.width - lineWidth) / 2,
        handleRect.top + (handleRect.height - lineHeight) / 2,
        lineWidth,
        lineHeight,
      );

      canvas.drawRect(lineRect, visualFillPaint);

      TouchyObjectPainter(
        touchyCanvas,
        gestureRouter: gestureRouter,
        interactionContext: ObjectResizeInteraction(
          targetObject: object,
          handle: handle,
        ),
        isInteractive: isInteractive,
      ).drawRect(handleRect, hitBoxFillPaint);
    }
  }

  void _drawResizeCorners(
    TouchyCanvas touchyCanvas,
    Canvas canvas,
    CanvasObject object,
  ) {
    final scale = ref.read(canvasViewportProvider).value.getMaxScaleOnAxis();
    final handleSize = 16.0 / scale;
    final borderRadius = 3.0 / scale;
    final borderWidth = 2.5 / scale;

    final selectionColor = ThemeHelper.blue500(context);
    final backgroundColor = ThemeHelper.neutral100(context);

    final cornerHandles = [
      ResizeHandle.topLeft,
      ResizeHandle.topRight,
      ResizeHandle.bottomLeft,
      ResizeHandle.bottomRight,
    ];

    final topLeftPos = object.topLeft;
    final topRightPos = Offset(object.bottomRight.dx, object.topLeft.dy);
    final bottomLeftPos = Offset(object.topLeft.dx, object.bottomRight.dy);
    final bottomRightPos = object.bottomRight;

    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = .fill;

    final borderPaint = Paint()
      ..color = selectionColor
      ..style = .stroke
      ..strokeWidth = borderWidth;

    for (final handle in cornerHandles) {
      final Offset cornerPos = switch (handle) {
        ResizeHandle.topLeft => topLeftPos,
        ResizeHandle.topRight => topRightPos,
        ResizeHandle.bottomLeft => bottomLeftPos,
        ResizeHandle.bottomRight => bottomRightPos,
        _ => .zero,
      };

      final handleRect = Rect.fromLTWH(
        cornerPos.dx - handleSize / 2,
        cornerPos.dy - handleSize / 2,
        handleSize,
        handleSize,
      );

      TouchyObjectPainter(
        touchyCanvas,
        gestureRouter: gestureRouter,
        interactionContext: ObjectResizeInteraction(
          targetObject: object,
          handle: handle,
        ),
        isInteractive: isInteractive,
      ).drawRect(handleRect, fillPaint);

      canvas.drawRRect(
        RRect.fromRectAndRadius(handleRect, .circular(borderRadius)),
        borderPaint,
      );
    }
  }

  void _drawArrowResizeHandles(
    TouchyCanvas touchyCanvas,
    Canvas canvas,
    CanvasObject object,
  ) {
    if (!object.isArrow) return;

    final gestureState = ref.read(canvasGestureStateProvider);
    if (gestureState.activeObject != null &&
        gestureState.activeObject!.isArrow &&
        gestureState.arrowMoveType != ArrowMoveType.none) {
      return;
    }

    if (object.arrowProps.points.length <= 1 ||
        object.arrowProps.arrowType == ArrowType.curved) {
      return;
    }

    final points = object.arrowProps.points;
    final scale = ref.read(canvasViewportProvider).value.getMaxScaleOnAxis();
    final selectionColor = ThemeHelper.blue500(context);

    // Calculate hit rectangles for each arrow segment (copied from CanvasArrowInteractive._getArrowSegmentHitRects)
    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      // Calculate segment length
      final segmentLength = (end - start).distance;

      // Check if this is first or last segment
      final isFirstSegment = i == 0;
      final isLastSegment = i == points.length - 2;

      // Skip drawing handle if segment is short and first/last
      if (segmentLength < CanvasBounds.gridSpacing * 3 &&
          (isFirstSegment || isLastSegment)) {
        continue;
      }

      // Calculate segment midpoint
      final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

      // Determine if segment is more horizontal or vertical
      final deltaX = (end.dx - start.dx).abs();
      final deltaY = (end.dy - start.dy).abs();
      final isHorizontal = deltaX >= deltaY;

      // Create rectangle at segment midpoint with proper orientation
      final Rect handleRect;
      if (isHorizontal) {
        // Horizontal segment: 20.0/scale wide × 6.0/scale tall
        final width = 20.0 / scale;
        final height = 6.0 / scale;
        handleRect = Rect.fromCenter(
          center: midpoint,
          width: width,
          height: height,
        );
      } else {
        // Vertical segment: 6.0/scale wide × 20.0/scale tall
        final width = 6.0 / scale;
        final height = 20.0 / scale;
        handleRect = Rect.fromCenter(
          center: midpoint,
          width: width,
          height: height,
        );
      }

      // Create interaction context for this arrow segment
      final arrowResizeInteraction = ArrowResizeInteraction(
        targetObject: object,
        segmentIndex: i,
      );

      // Step 1: Draw visual handle using regular canvas (rounded rectangle with selection color)
      final handlePaint = Paint()
        ..color = selectionColor
        ..style = .fill;

      final borderRadius = 3.0 / scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(handleRect, .circular(borderRadius)),
        handlePaint,
      );

      // Step 2: Draw transparent TouchyObjectPainter rectangle for interaction
      // Expand hit area to be more finger-friendly (minimum 24x24 pixels)
      final minHitSize = 24.0 / scale;
      final expandedWidth = max(handleRect.width, minHitSize);
      final expandedHeight = max(handleRect.height, minHitSize);

      // Calculate expanded rectangle centered on original handle
      final expandedRect = Rect.fromCenter(
        center: handleRect.center,
        width: expandedWidth,
        height: expandedHeight,
      );

      final arrowHandlePainter = TouchyObjectPainter(
        touchyCanvas,
        gestureRouter: gestureRouter,
        interactionContext: arrowResizeInteraction,
        isInteractive: isInteractive,
      );

      // Create transparent paint for interaction area
      final transparentPaint = Paint()
        ..color = Colors.transparent
        ..style = .fill;

      // Draw the transparent interaction rectangle
      arrowHandlePainter.drawRect(expandedRect, transparentPaint);
    }
  }

  void _drawArrowMoveHandles(TouchyCanvas touchyCanvas, CanvasObject object) {
    if (!object.isArrow) return;

    final gestureState = ref.read(canvasGestureStateProvider);
    if (gestureState.activeObject != null &&
        gestureState.activeObject!.isArrow &&
        gestureState.arrowMoveType != ArrowMoveType.none) {
      return;
    }

    final scale = ref.read(canvasViewportProvider).value.getMaxScaleOnAxis();
    final arrowProps = object.arrowProps;

    // Calculate start point
    Offset startPoint;
    if (arrowProps.startObjectId != null) {
      final startObj = object.getStartObject(ref);
      startPoint = startObj != null
          ? arrowProps.startPoint.getOffset(startObj) +
                (arrowProps.startRelativeOffset ?? .zero)
          : (arrowProps.startAbsoluteOffset ?? .zero);
    } else {
      startPoint = arrowProps.startAbsoluteOffset ?? .zero;
    }

    // Calculate end point
    Offset endPoint;
    if (arrowProps.endObjectId != null) {
      final endObj = object.getEndObject(ref);
      endPoint = endObj != null
          ? arrowProps.endPoint.getOffset(endObj) +
                (arrowProps.endRelativeOffset ?? .zero)
          : (arrowProps.endAbsoluteOffset ?? .zero);
    } else {
      endPoint = arrowProps.endAbsoluteOffset ?? .zero;
    }

    ArrowPointPainter.paint(
      touchyCanvas: touchyCanvas,
      context: context,
      gestureRouter: gestureRouter,
      interactionContext: ArrowMoveInteraction(
        targetObject: object,
        moveType: ArrowMoveType.start,
      ),
      center: startPoint,
      scale: scale,
      isInteractive: isInteractive,
    );

    ArrowPointPainter.paint(
      touchyCanvas: touchyCanvas,
      context: context,
      gestureRouter: gestureRouter,
      interactionContext: ArrowMoveInteraction(
        targetObject: object,
        moveType: ArrowMoveType.end,
      ),
      center: endPoint,
      scale: scale,
      isInteractive: isInteractive,
    );
  }

  void _drawArrowToolWell(TouchyCanvas touchyCanvas, Canvas canvas) {
    if (ref.read(toolModeProvider) != ToolMode.arrow ||
        arrowToolPrimedData == null ||
        ref.read(canvasGestureStateProvider).interactionContext != null) {
      return;
    }

    ArrowPointPainter.paint(
      touchyCanvas: touchyCanvas,
      context: context,
      gestureRouter: gestureRouter,
      interactionContext: ArrowToolWellInteraction(
        sourceObject: arrowToolPrimedData!.object,
        startOffset: arrowToolPrimedData!.relativeOffset,
        closestEdge: arrowToolPrimedData!.closestEdge,
      ),
      center: arrowToolPrimedData!.absolutePosition,
      scale: ref.read(canvasViewportProvider).value.getMaxScaleOnAxis(),
      isInteractive: isInteractive,
    );
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    return oldDelegate.objects != objects ||
        oldDelegate.selectedObjects != selectedObjects ||
        oldDelegate.draggedObjects != draggedObjects ||
        oldDelegate.arrowPrimedObjects != arrowPrimedObjects ||
        oldDelegate.dragSelect != dragSelect ||
        oldDelegate.textEditedObjId != textEditedObjId ||
        oldDelegate.potentialDropTargetId != potentialDropTargetId ||
        oldDelegate.arrowPreview != arrowPreview ||
        oldDelegate.arrowToolPrimedData != arrowToolPrimedData;
  }
}
