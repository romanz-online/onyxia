import 'package:onyxia/export.dart';
import 'dart:math' as math;
import '../providers/providers.dart';
import 'interaction_service.dart';
import '../../../../helpers/clipboard_helper.dart' as web_helper;
import 'clipboard_paste_handler.dart' as paste_handler;

/// Service for handling canvas object clipboard operations using system clipboard
/// with NCON (Narwhal Canvas Object Notation) format
class CanvasClipboardService {
  static Offset? _lastPastedPosition;
  static int _consequentPastes = 0;

  static Future<void> copy({required List<CanvasObject> objects}) async {
    if (objects.isEmpty) return;

    try {
      await Clipboard.setData(ClipboardData(
        text: 'NCON:${jsonEncode(objects.map((obj) => obj.toMap()).toList())}',
      ));
    } catch (e) {
      return;
    }
  }

  /// Handle paste events (web-specific, delegates to platform implementation)
  void handleJsPaste(dynamic event, WidgetRef ref, BuildContext context) {
    paste_handler.handleJsPasteImpl(event, ref, context);
  }

  /// Pastes canvas objects from system clipboard if in NCON format
  /// Returns tuple of (objects, pins) - pins always empty for now
  static Future<(List<CanvasObject>, List<Pin>)> paste({
    required Offset targetPosition,
    required WidgetRef ref,
  }) async {
    if (!ref.read(canvasConfigProvider).allowPasting) {
      return (<CanvasObject>[], <Pin>[]);
    }

    try {
      final hasFiles = await web_helper.hasFilesInClipboard();
      if (hasFiles) return (<CanvasObject>[], <Pin>[]);

      // NCON
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text;

      if (text == null || text.isEmpty) return (<CanvasObject>[], <Pin>[]);

      if (_isNcon(text)) {
        return _nconToObjects(
          text: text,
          targetPosition: targetPosition,
          ref: ref,
        );
      }

      // fallback to text object
      if (text.isNotEmpty) {
        final objectsNotifier = ref.read(canvasObjectsProvider.notifier);
        final viewportCenter =
            ref.read(canvasViewportProvider.notifier).getViewportCenter();

        final newObj = CanvasObject(
          id: const Uuid().v4(),
          type: CanvasObjectType.text,
          topLeft: viewportCenter,
          bottomRight: viewportCenter,
          createdAt: DateTime.now(),
          color: Colors.transparent,
          layer: objectsNotifier.nextLayer(),
          content: text,
        );

        ref.read(canvasObjectsProvider.notifier).addObjectState(newObj);
        ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
        ref.read(canvasObjectsProvider.notifier).selectObject(newObj);
        CanvasInteractionService.openTextEditor(ref: ref);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final renderBox = newObj.textAreaKey.currentContext
              ?.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.hasSize) {
            final containerSize = renderBox.size;
            newObj.bottomRight = newObj.topLeft +
                Offset(containerSize.width, containerSize.height);
          }

          ref.read(canvasObjectsProvider.notifier).addObject(ref, newObj);
          CanvasInteractionService.closeTextEditor(ref: ref);
        });
      }

      // none of the above -- return nothing
      return (<CanvasObject>[], <Pin>[]);
    } catch (e) {
      return (<CanvasObject>[], <Pin>[]);
    }
  }

  static (List<CanvasObject>, List<Pin>) _nconToObjects({
    required String text,
    required Offset targetPosition,
    required WidgetRef ref,
  }) {
    final nconContent = text.substring(5); // Remove "NCON:" prefix
    final List<dynamic> objectsList = jsonDecode(nconContent);
    final List<CanvasObject> objects = objectsList
        .map((objMap) => CanvasObject.fromMap(objMap as Map<String, dynamic>))
        .toList();

    if (objects.isEmpty) return (<CanvasObject>[], <Pin>[]);

    // Calculate selection center from object bounds
    final bounds = _calculateSelectionBounds(objects);
    final selectionCenter = Offset(
      bounds.left + bounds.width / 2,
      bounds.top + bounds.height / 2,
    );

    // Calculate consecutive paste offset
    Offset pasteTranslation;
    if (targetPosition == _lastPastedPosition) {
      _consequentPastes++;
      pasteTranslation = Offset(
        CanvasBounds.gridSpacing * _consequentPastes,
        CanvasBounds.gridSpacing * _consequentPastes,
      );
    } else {
      _lastPastedPosition = targetPosition;
      _consequentPastes = 0;
      pasteTranslation = Offset.zero;
    }

    // Calculate the initial offset difference
    final initialOffsetDifference = targetPosition - selectionCenter;

    // Pre-calculate the bounds of all objects if pasted at the target position
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final obj in objects) {
      final newTopLeft =
          obj.topLeft + initialOffsetDifference + pasteTranslation;
      final newBottomRight =
          obj.bottomRight + initialOffsetDifference + pasteTranslation;

      minX = math.min(minX, newTopLeft.dx);
      minY = math.min(minY, newTopLeft.dy);
      maxX = math.max(maxX, newBottomRight.dx);
      maxY = math.max(maxY, newBottomRight.dy);
    }

    // Calculate adjustments needed to keep all objects within canvas bounds
    final canvasBounds = ref.read(canvasBoundsProvider).bounds;
    Offset adjustment = Offset.zero;

    if (maxX > canvasBounds.right) {
      adjustment =
          Offset(adjustment.dx - (maxX - canvasBounds.right), adjustment.dy);
    }
    if (maxY > canvasBounds.bottom) {
      adjustment =
          Offset(adjustment.dx, adjustment.dy - (maxY - canvasBounds.bottom));
    }
    if (minX < canvasBounds.left) {
      adjustment =
          Offset(adjustment.dx + (canvasBounds.left - minX), adjustment.dy);
    }
    if (minY < canvasBounds.top) {
      adjustment =
          Offset(adjustment.dx, adjustment.dy + (canvasBounds.top - minY));
    }

    final adjustedOffset = initialOffsetDifference + adjustment;

    final Map<String, String> idMapping = {};
    final List<CanvasObject> pastedObjects = [];
    final List<Pin> pastedPins = [];
    for (final obj in objects.where((e) => !e.isArrow)) {
      final newObj = CanvasObject.fromJson(obj.toJson());
      newObj.id = const Uuid().v4();
      idMapping[obj.id] = newObj.id;

      final canvasBoundsNotifier = ref.read(canvasBoundsProvider.notifier);
      newObj.topLeft = canvasBoundsNotifier.snap(
          (newObj.topLeft + adjustedOffset)
              .translate(pasteTranslation.dx, pasteTranslation.dy));
      newObj.bottomRight = (newObj.bottomRight + adjustedOffset)
          .translate(pasteTranslation.dx, pasteTranslation.dy);

      pastedObjects.add(newObj);
    }

    for (final obj in objects.where((e) => e.isArrow)) {
      final newArrow = CanvasObject.fromJson(obj.toJson());
      newArrow.id = const Uuid().v4();

      newArrow.topLeft = (newArrow.topLeft + adjustedOffset)
          .translate(pasteTranslation.dx, pasteTranslation.dy);
      newArrow.bottomRight = (newArrow.bottomRight + adjustedOffset)
          .translate(pasteTranslation.dx, pasteTranslation.dy);

      if (idMapping.containsKey(obj.arrowProps.startObjectId)) {
        newArrow.arrowProps.startObjectId =
            idMapping[obj.arrowProps.startObjectId]!;
      }

      if (idMapping.containsKey(obj.arrowProps.endObjectId)) {
        newArrow.arrowProps.endObjectId = idMapping[obj.arrowProps.endObjectId];
      }

      newArrow.arrowProps.points = newArrow.arrowProps.points
          .map((keypoint) => (keypoint + adjustedOffset)
              .translate(pasteTranslation.dx, pasteTranslation.dy))
          .toList();

      pastedObjects.add(newArrow);
    }

    return (pastedObjects, pastedPins);
  }

  static Rect _calculateSelectionBounds(List<CanvasObject> objects) {
    if (objects.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final obj in objects) {
      minX = math.min(minX, obj.topLeft.dx);
      minY = math.min(minY, obj.topLeft.dy);
      maxX = math.max(maxX, obj.bottomRight.dx);
      maxY = math.max(maxY, obj.bottomRight.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static bool _isNcon(String text) => text.startsWith('NCON:');
}
