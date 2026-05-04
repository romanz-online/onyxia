import 'package:onyxia/export.dart';
import 'canvas_right_click_menu.dart';
import '../providers/providers.dart';

enum RightClickMenuOption {
  addComment,
  addArtifact,
  paste,
  cut,
  copy,
  delete,
  snapToGrid,
  showMinimap,
  showToolbar,
  importImage,
  getDiagramLink,
  arrange,
  sendBackward,
  sendToBack,
  bringForward,
  bringToFront,
}

const List<RightClickMenuOption> whitespaceOptions = [
  RightClickMenuOption.addComment,
  RightClickMenuOption.paste,
  RightClickMenuOption.snapToGrid,
  RightClickMenuOption.showMinimap,
  RightClickMenuOption.showToolbar,
  RightClickMenuOption.getDiagramLink,
];

const List<RightClickMenuOption> objectOptions = [
  RightClickMenuOption.addComment,
  RightClickMenuOption.addArtifact,
  RightClickMenuOption.cut,
  RightClickMenuOption.copy,
  RightClickMenuOption.delete,
  RightClickMenuOption.arrange,
];

void canvasRightClick(
  BuildContext context,
  bool isMarkup,
  Offset globalPosition,
  Offset localPosition,
  WidgetRef ref, {
  CanvasObject? clickedObj,
}) {
  // Always close existing menu first - this ensures clean state
  _closeAllMenus();

  if (clickedObj == null) {
    List<RightClickMenuOption> options = List.from(whitespaceOptions);

    if (isMarkup) {
      options.remove(RightClickMenuOption.paste);
      options.remove(RightClickMenuOption.snapToGrid);
      options.remove(RightClickMenuOption.showToolbar);
      options.add(RightClickMenuOption.addArtifact);
    }

    createMenu(
      context,
      isMarkup,
      globalPosition,
      localPosition,
      ref,
      options,
      clickedObj,
    );
  } else {
    if (!ref.read(canvasObjectsProvider).selectedObjects.contains(clickedObj)) {
      ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
      ref.read(canvasObjectsProvider.notifier).selectObject(clickedObj);
    }

    List<RightClickMenuOption> options = List.from(objectOptions);

    createMenu(
      context,
      isMarkup,
      globalPosition,
      localPosition,
      ref,
      options,
      clickedObj,
    );
  }
}

OverlayEntry? _activeMenuOverlay;

void createMenu(
  BuildContext context,
  bool isMarkup,
  Offset globalPosition,
  Offset localPosition,
  WidgetRef ref,
  List<RightClickMenuOption> options,
  CanvasObject? clickedObj,
) {
  // Close any existing menus first
  _closeAllMenus();

  _activeMenuOverlay = OverlayEntry(
    builder: (context) => CanvasRightClickMenu(
      //key: UniqueKey(),
      isMarkup: isMarkup,
      options: options,
      globalPosition: globalPosition,
      localPosition: localPosition,
      ref: ref,
      clickedObj: clickedObj,
      onClose: _closeAllMenus,
    ),
  );

  Overlay.of(context).insert(_activeMenuOverlay!);
}

void _closeAllMenus() {
  if (_activeMenuOverlay != null) {
    _activeMenuOverlay!.remove();
    _activeMenuOverlay!.dispose();
    _activeMenuOverlay = null;
  }
}

void pasteArtifactAtPosition(
  Note note,
  Offset position,
  BuildContext ctx,
  WidgetRef ref,
) {
  final objects = ref.read(canvasObjectsProvider).objects;
  final object = objects.firstWhere(
    (obj) => obj.isPointInObject(position),
    orElse: () => CanvasObject.initial(),
  );

  if (object.id.isNotEmpty) {
    Size objSize = object.getDimensions();
    Offset newPosition = position - object.topLeft;
    newPosition = Offset(
      newPosition.dx / objSize.width,
      newPosition.dy / objSize.height,
    );

    ref.read(pinsProvider.notifier).addPin(
          ref,
          Pin(
            id: const Uuid().v4(),
            artifactId: note.id,
            canvasId: ref.read(currentCanvasProvider)?.id ?? '',
            position: newPosition,
            pinnedObjectId: object.id,
          ),
        );

    NarwhalToast.show(
      text: 'Pin "${note.title}" pasted onto object',
      type: ToastType.success,
    );
  } else {
    NarwhalToast.show(
      text: 'Pins can only be added to objects',
      type: ToastType.error,
    );
  }
}
