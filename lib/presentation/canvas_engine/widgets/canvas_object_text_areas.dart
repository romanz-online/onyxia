import 'dart:math' as math;
import 'package:onyxia/export.dart';
import '../gestures/gestures.dart';
import '../providers/providers.dart';
import 'canvas_gesture_detector.dart';

class CanvasObjectTextArea extends ConsumerWidget {
  final BuildContext context;
  final CanvasObject canvasObject;
  final CanvasTextState objectTextState;
  final CanvasGestureRouter gestureRouter;
  final Function(CanvasObject) onTextKeyPress;

  const CanvasObjectTextArea({
    super.key,
    required this.context,
    required this.canvasObject,
    required this.objectTextState,
    required this.gestureRouter,
    required this.onTextKeyPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final bool isEditing = objectTextState.editingObjId == canvasObject.id;
      final bool isSelected = ref
          .read(canvasObjectsProvider)
          .selectedObjects
          .contains(canvasObject);

      if (canvasObject.isBrush || canvasObject.isImage)
        return const SizedBox.shrink();

      if (isSelected &&
          !isEditing &&
          canvasObject.isContentEmpty &&
          canvasObject.type != .text) {
        return _buildHoverHint(ref: ref);
      }

      if (!isEditing && !canvasObject.isContentEmpty) {
        return canvasObject.type == .text
            ? _buildTextViewer(ref: ref)
            : _buildNormalViewer(ref: ref);
      }

      if (isEditing) {
        return canvasObject.type == .text
            ? _buildTextEditor(ref: ref)
            : _buildNormalEditor(ref: ref);
      }

      return const SizedBox.shrink();
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildHoverHint({required WidgetRef ref}) {
    final interactionContext = ObjectFillInteractionContext(
      targetObject: canvasObject,
    );
    return Positioned(
      left: canvasObject.topLeft.dx,
      top: canvasObject.topLeft.dy,
      width: (canvasObject.bottomRight.dx - canvasObject.topLeft.dx).abs(),
      height: (canvasObject.bottomRight.dy - canvasObject.topLeft.dy).abs(),
      child: HoverBuilder(
        builder: (context, isHovered) {
          return GestureDetector(
            onTapDown: gestureRouter.getHandleTapDown(interactionContext),
            onTapUp: gestureRouter.getHandleTapUp(interactionContext),
            // onPanDown: gestureRouter.getHandlePanDown(interactionContext), // DO NOT ADD THIS. IT BREAKS EVERYTHING
            onPanStart: gestureRouter.getHandlePanStart(interactionContext),
            onPanUpdate: gestureRouter.getHandlePanUpdate(),
            onPanEnd: gestureRouter.getHandlePanEnd(),
            onSecondaryTapDown: gestureRouter.getHandleSecondaryTapDown(
              interactionContext,
            ),
            onSecondaryTapUp: gestureRouter.getHandleSecondaryTapUp(
              interactionContext,
            ),
            child: Center(
              child: Text(
                isHovered ? 'Add Text' : '',
                style: TextStyle(
                  fontSize: 17,
                  color: ThemeHelper.foreground2().withValues(alpha: 0.6),
                  fontWeight: .w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNormalEditor({required WidgetRef ref}) {
    const double padding = 5.0;
    final Rect innerRect = canvasObject.findInnerRect();
    final double maxWidth = innerRect.width - padding * 2;
    final double maxHeight = innerRect.height - padding * 2;
    final Offset position = innerRect.topLeft;
    final double centerX = position.dx + (maxWidth / 2);
    final double centerY = position.dy + (maxHeight / 2);

    return Positioned(
      left: centerX + padding,
      top: centerY + padding,
      width: maxWidth,
      child: Transform.translate(
        offset: const Offset(-0.5, -0.5),
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: Container(
              padding: .only(left: 1, top: 1),
              child: IntrinsicWidth(
                child: IntrinsicHeight(
                  child: TextField(
                    controller: ref.watch(canvasTextProvider).controller,
                    focusNode: ref.watch(canvasTextProvider).focusNode,
                    autofocus: true,
                    maxLines: null,
                    style: TextStyle(
                      color: ThemeHelper.foreground1(),
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      border: .none,
                      contentPadding: .zero,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      canvasObject.content = ref
                          .read(canvasTextProvider.notifier)
                          .text;
                      onTextKeyPress(canvasObject);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormalViewer({required WidgetRef ref}) {
    const double padding = 5.0;
    final Rect innerRect = canvasObject.findInnerRect();
    final double maxWidth = innerRect.width - padding * 2;
    final double maxHeight = innerRect.height - padding * 2;
    final Offset position = innerRect.topLeft;
    final double centerX = position.dx + (maxWidth / 2);
    final double centerY = position.dy + (maxHeight / 2);

    final interactionContext = ObjectFillInteractionContext(
      targetObject: canvasObject,
    );

    return Positioned(
      left: centerX + padding,
      top: centerY + padding,
      width: maxWidth,
      child: Transform.translate(
        offset: const Offset(-0.5, -0.5),
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: GestureDetector(
              onTapDown: gestureRouter.getHandleTapDown(interactionContext),
              onTapUp: gestureRouter.getHandleTapUp(interactionContext),
              // onPanDown: gestureRouter.getHandlePanDown(interactionContext), // DO NOT ADD THIS. IT BREAKS EVERYTHING
              onPanStart: gestureRouter.getHandlePanStart(interactionContext),
              onPanUpdate: gestureRouter.getHandlePanUpdate(),
              onPanEnd: gestureRouter.getHandlePanEnd(),
              onSecondaryTapDown: gestureRouter.getHandleSecondaryTapDown(
                interactionContext,
              ),
              onSecondaryTapUp: gestureRouter.getHandleSecondaryTapUp(
                interactionContext,
              ),
              child: Center(
                child: Text(
                  canvasObject.content,
                  style: TextStyle(
                    color: ThemeHelper.foreground1(),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextEditor({required WidgetRef ref}) {
    return Positioned(
      left: canvasObject.topLeft.dx,
      top: canvasObject.topLeft.dy,
      child: Container(
        key: canvasObject.textAreaKey,
        decoration: BoxDecoration(
          border: .all(color: ThemeHelper.accent(), width: 1.5),
        ),
        padding: .all(5.0),
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: TextField(
              controller: ref.watch(canvasTextProvider).controller,
              focusNode: ref.watch(canvasTextProvider).focusNode,
              autofocus: true,
              maxLines: null,
              style: TextStyle(color: ThemeHelper.foreground1(), fontSize: 16),
              decoration: const InputDecoration(
                border: .none,
                contentPadding: .zero,
                isDense: true,
                hintText: 'Enter text',
              ),
              onChanged: (value) {
                canvasObject.content = ref
                    .read(canvasTextProvider.notifier)
                    .text;
                final renderBox =
                    canvasObject.textAreaKey.currentContext?.findRenderObject()
                        as RenderBox?;
                if (renderBox != null && renderBox.hasSize) {
                  final containerSize = renderBox.size;
                  canvasObject.bottomRight =
                      canvasObject.topLeft +
                      Offset(containerSize.width, containerSize.height);
                }
                onTextKeyPress(canvasObject);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextViewer({required WidgetRef ref}) {
    final interactionContext = ObjectFillInteractionContext(
      targetObject: canvasObject,
    );

    return Positioned(
      left: canvasObject.topLeft.dx,
      top: canvasObject.topLeft.dy,
      child: GestureDetector(
        onTapDown: gestureRouter.getHandleTapDown(interactionContext),
        onTapUp: gestureRouter.getHandleTapUp(interactionContext),
        // onPanDown: gestureRouter.getHandlePanDown(interactionContext), // DO NOT ADD THIS. IT BREAKS EVERYTHING
        onPanStart: gestureRouter.getHandlePanStart(interactionContext),
        onPanUpdate: gestureRouter.getHandlePanUpdate(),
        onPanEnd: gestureRouter.getHandlePanEnd(),
        onSecondaryTapDown: gestureRouter.getHandleSecondaryTapDown(
          interactionContext,
        ),
        onSecondaryTapUp: gestureRouter.getHandleSecondaryTapUp(
          interactionContext,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: .all(
              color:
                  ref
                      .read(canvasObjectsProvider)
                      .selectedObjects
                      .contains(canvasObject)
                  ? ThemeHelper.accent()
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: .all(5.0),
          child: IntrinsicWidth(
            child: IntrinsicHeight(
              child: Text(
                canvasObject.content,
                style: TextStyle(
                  color: ThemeHelper.foreground1(),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CanvasArrowTextArea extends ConsumerWidget {
  final BuildContext context;
  final CanvasObject canvasObject;
  final CanvasGestureRouter gestureRouter;
  final CanvasTextState objectTextState;
  final Function(CanvasObject) onTextKeyPress;

  const CanvasArrowTextArea({
    super.key,
    required this.context,
    required this.canvasObject,
    required this.gestureRouter,
    required this.objectTextState,
    required this.onTextKeyPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final bool isEditing = objectTextState.editingObjId == canvasObject.id;

      if (!isEditing && !canvasObject.isContentEmpty) {
        return _buildArrowViewer(ref: ref);
      }

      if (isEditing) {
        return _buildArrowEditor(ref: ref);
      }

      return const SizedBox.shrink();
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildArrowEditor({required WidgetRef ref}) {
    double maxWidth;
    double maxHeight;
    final Offset position = canvasObject.getTextOffset();
    const double padding = 5.0;

    final keypoints = canvasObject.arrowProps.points;

    if (keypoints.length >= 2) {
      double totalLength = 0.0;
      for (int i = 0; i < canvasObject.arrowProps.points.length - 1; i++) {
        totalLength +=
            (canvasObject.arrowProps.points[i + 1] -
                    canvasObject.arrowProps.points[i])
                .distance;
      }
      maxWidth = math.max(totalLength * 0.3, 100.0) + padding * 2;
      maxHeight = math.min(maxWidth * 0.6, 100.0);
    } else {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: Container(
            padding: .all(padding),
            decoration: BoxDecoration(
              color: ThemeHelper.background1(),
              border: .all(color: ThemeHelper.accent(), width: 3.0),
              borderRadius: .circular(8.0),
            ),
            child: Container(
              color: ThemeHelper.background1().withAlpha(10),
              child: IntrinsicWidth(
                child: IntrinsicHeight(
                  child: TextField(
                    controller: ref.watch(canvasTextProvider).controller,
                    focusNode: ref.watch(canvasTextProvider).focusNode,
                    autofocus: true,
                    maxLines: null,
                    style: TextStyle(
                      color: ThemeHelper.foreground1(),
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      border: .none,
                      contentPadding: .zero,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      canvasObject.content = ref
                          .read(canvasTextProvider.notifier)
                          .text;
                      onTextKeyPress(canvasObject);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrowViewer({required WidgetRef ref}) {
    final isSelected = ref
        .read(canvasObjectsProvider)
        .selectedObjects
        .contains(canvasObject);
    const double padding = 5.0;
    final position = canvasObject.getTextOffset();

    if (canvasObject.arrowProps.points.isEmpty) return const SizedBox.shrink();

    double totalLength = 0.0;
    for (int i = 0; i < canvasObject.arrowProps.points.length - 1; i++) {
      totalLength +=
          (canvasObject.arrowProps.points[i + 1] -
                  canvasObject.arrowProps.points[i])
              .distance;
    }

    final maxWidth = math.max(totalLength * 0.3, 100.0) + padding * 2;
    final maxHeight = math.min(maxWidth * 0.6, 100.0);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Consumer(
          builder: (context, ref, _) {
            Widget textWidget = ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: IntrinsicWidth(
                child: IntrinsicHeight(
                  child: Container(
                    padding: .all(padding),
                    decoration: BoxDecoration(
                      color: ThemeHelper.background1(),
                      border: .all(
                        color: isSelected
                            ? ThemeHelper.accent()
                            : canvasObject.color,
                        width: 3.0,
                      ),
                      borderRadius: .circular(8.0),
                    ),
                    child: Text(
                      canvasObject.content,
                      style: TextStyle(
                        color: ThemeHelper.foreground1(),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            );

            return CanvasGestureDetector(
              gestureKey: canvasObject.arrowTextAreaKey,
              gestureRouter: gestureRouter,
              interactionContext: ArrowTextInteraction(
                targetObject: canvasObject,
              ),
              behavior: .opaque,
              child: textWidget,
            );
          },
        ),
      ),
    );
  }
}
