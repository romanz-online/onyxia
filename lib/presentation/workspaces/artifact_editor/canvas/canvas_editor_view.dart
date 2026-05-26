import 'package:onyxia/export.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/canvas_pin.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:touchable/touchable.dart';
import 'package:onyxia/presentation/canvas_engine/gestures/gestures.dart';
import 'package:onyxia/presentation/canvas_engine/services/services.dart';
import 'package:onyxia/presentation/canvas_engine/providers/providers.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/arrow_wells_overlay.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/background.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/canvas_comment_pin.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/canvas_comment_pin_expanded.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/canvas_cursor_overlay.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/canvas_object_menu.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/canvas_object_text_areas.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/canvas_pin_expanded.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/drag_off_bar.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/headless_palette.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/painter/canvas_painter.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/toolbar.dart';
import 'package:onyxia/presentation/canvas_engine/canvas_config.dart';
import 'package:onyxia/presentation/canvas_engine/utils/image_drag_data.dart';
import 'dart:async';

class CanvasEditorView extends ConsumerStatefulWidget {
  final String canvasId;

  const CanvasEditorView({super.key, required this.canvasId});

  @override
  ConsumerState<CanvasEditorView> createState() => _CanvasEditorView();
}

class _CanvasEditorView extends ConsumerState<CanvasEditorView> {
  late CanvasGestureRouter _gestureRouter;
  CanvasConfig? _routerConfig;
  CanvasPainter? _canvasPainter;
  Timer? _textSaveTimer;
  ExpandablePin? _expandedPin;
  final ValueNotifier<bool> _isDragHovering = ValueNotifier<bool>(false);

  void _ensureRouter(CanvasConfig config) {
    if (_routerConfig != config) {
      _gestureRouter = CanvasGestureRouter(
        ref: ref,
        context: context,
        canvasConfig: config,
      );
      _routerConfig = config;
    }
  }

  void _expandPin(ExpandablePin pin) => setState(() => _expandedPin = pin);
  void _collapsePin() => setState(() => _expandedPin = null);
  bool _isPinExpanded(String id) => _expandedPin?.id == id;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      CanvasLoaderService.setupCanvas(
        ref: ref,
        canvasId: widget.canvasId,
        context: context,
        onCollapsePin: _collapsePin,
      );
    });
  }

  @override
  void dispose() {
    _textSaveTimer?.cancel();
    _isDragHovering.dispose();
    CanvasLoaderService.cleanupCanvas(context: context);
    super.dispose();
  }

  void _debouncedTextSave(CanvasObject obj) {
    ref.read(canvasObjectsProvider.notifier).updateObjectState(obj);
    _textSaveTimer?.cancel();
    _textSaveTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref.read(canvasObjectsProvider.notifier).updateObject(obj);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedArtifactProvider);
    final currentCanvas = selected is CanvasArtifact ? selected : null;
    final canvasBounds = ref.watch(canvasBoundsProvider);

    if (canvasBounds.isLoading) {
      return Scaffold(body: Center(child: OnyxiaLoadingIndicator()));
    }

    if (currentCanvas == null) {
      return Scaffold(body: Center(child: Text('Canvas not found')));
    }

    final objects = ref.watch(canvasObjectsProvider);
    final selectedTool = ref.watch(toolModeProvider);
    final objectText = ref.watch(canvasTextProvider);
    final canvasCommentsState = ref.watch(commentsProvider);
    final showArtifacts = ref.watch(canvasSettingsProvider(.showArtifacts));
    final showComments = ref.watch(canvasSettingsProvider(.showComments));
    final showToolbar = ref.watch(canvasSettingsProvider(.showToolbar));
    final arrowPreview = ref.watch(arrowPreviewProvider);
    final headlessState = ref.watch(headlessProvider);
    final pins = ref.watch(pinsProvider);

    final comments = [
      ...canvasCommentsState.comments,
      if (canvasCommentsState.temporaryComment != null)
        canvasCommentsState.temporaryComment!,
    ];

    _ensureRouter(ref.watch(canvasConfigProvider));

    return Stack(
      children: [
        Stack(
          children: [
            _buildCanvas(
              canvas: currentCanvas,
              objects: objects,
              selectedTool: selectedTool,
              objectTextState: objectText,
              comments: comments,
              pins: pins,
              showArtifacts: showArtifacts,
              showComments: showComments,
              arrowPreview: arrowPreview,
            ),
            _buildImageDropRegion(ref),
            CanvasObjectMenu(
              openTextEditor: () =>
                  CanvasInteractionService.openTextEditor(ref: ref),
              closeTextEditor: () =>
                  CanvasInteractionService.closeTextEditor(ref: ref),
              saveTextEditor: _debouncedTextSave,
            ),
            if (showToolbar)
              if (currentCanvas.canvasType == .flow)
                DragOffBar(
                  buttons: [
                    DragOffBarButton(
                      icon: LucideIcons.fileText,
                      dragData: DragOffBarData(type: .note),
                      dragFeedbackBuilder: () =>
                          _buildArtifactDragFeedback(context),
                    ),
                  ],
                )
              else
                Toolbar(
                  closeTextEditor: () =>
                      CanvasInteractionService.closeTextEditor(ref: ref),
                ),
            if (headlessState.isVisible)
              HeadlessPalette(arrow: headlessState.headlessArrow!),
          ],
        ),
      ],
    );
  }

  Widget _buildCanvas({
    required CanvasArtifact canvas,
    required CanvasObjects objects,
    required ToolMode selectedTool,
    required CanvasTextState objectTextState,
    required List<Comment> comments,
    required Pins pins,
    required bool showArtifacts,
    required bool showComments,
    required ArrowPreview? arrowPreview,
  }) {
    final config = ref.watch(canvasConfigProvider);
    final viewportController = ref.watch(canvasViewportProvider);

    return Container(
      color: ThemeHelper.neutral200(context),
      child: Listener(
        onPointerDown: (_) =>
            ref.read(canvasMousePressedProvider.notifier).set(true),
        onPointerUp: (_) =>
            ref.read(canvasMousePressedProvider.notifier).set(false),
        onPointerCancel: (_) =>
            ref.read(canvasMousePressedProvider.notifier).set(false),
        child: InteractiveViewer(
          minScale: ref.read(canvasViewportProvider.notifier).minScale,
          maxScale: ref.read(canvasViewportProvider.notifier).maxScale,
          transformationController: viewportController,
          boundaryMargin: .zero,
          constrained: false,
          panEnabled: _gestureRouter.allowsViewportPanning,
          scaleEnabled: _gestureRouter.allowsViewportScaling,
          onInteractionUpdate: (details) => ref
              .read(canvasViewportProvider.notifier)
              .setTransformation(viewportController.value),
          onInteractionEnd: (details) => ref
              .read(canvasViewportProvider.notifier)
              .setTransformation(viewportController.value),
          child: CanvasCursorOverlay(
            child: Consumer(
              builder: (context, ref, child) {
                final canvasBounds = ref.watch(canvasBoundsProvider).bounds;
                return SizedBox(
                  width: canvasBounds.width,
                  height: canvasBounds.height,
                  child: Stack(
                    children: [
                      Positioned.fill(child: Background(canvas: canvas)),
                      NarwhalPaint(
                        child: SizedBox.fromSize(
                          size: canvasBounds.size,
                          child: CanvasTouchDetector(
                            gesturesToOverride: [
                              .onTapDown,
                              .onTapUp,
                              // onPanDown breaks things because it triggers at the same time as regular taps
                              // GestureType.onPanDown,
                              if (!_gestureRouter.allowsViewportPanning) ...[
                                // if statement allows InteractiveViewer to handle viewport panning when needed
                                .onPanStart,
                                .onPanUpdate,
                                .onPanEnd,
                              ],
                              .onSecondaryTapDown,
                              .onSecondaryTapUp,
                              .onHover,
                            ],
                            builder: (context) {
                              _canvasPainter = CanvasPainter(
                                ref: ref,
                                context: context,
                                gestureRouter: _gestureRouter,
                                objects: objects.objects,
                                selectedObjects: objects.selectedObjects,
                                draggedObjects: ref.watch(
                                  draggedObjectsProvider,
                                ),
                                dragSelect: ref
                                    .watch(dragSelectProvider)
                                    .dragRect,
                                arrowPrimedObjects: ref.watch(
                                  arrowPrimedObjectsProvider,
                                ),
                                arrowToolPrimedData: ref.watch(
                                  arrowToolPrimedObjectsProvider,
                                ),
                                textEditedObjId: ref
                                    .watch(canvasTextProvider)
                                    .editingObjId,
                                arrowPreview: arrowPreview,
                              );

                              return CustomPaint(
                                size: canvasBounds.size,
                                painter: _canvasPainter,
                              );
                            },
                          ),
                        ),
                      ),
                      ...objects.objects
                          .where((e) => !e.isArrow)
                          .map(
                            (obj) => CanvasObjectTextArea(
                              context: context,
                              canvasObject: obj,
                              gestureRouter: _gestureRouter,
                              objectTextState: objectTextState,
                              onTextKeyPress: _debouncedTextSave,
                            ),
                          ),
                      ...objects.objects
                          .where((e) => e.isArrow)
                          .map(
                            (obj) => CanvasArrowTextArea(
                              context: context,
                              canvasObject: obj,
                              gestureRouter: _gestureRouter,
                              objectTextState: objectTextState,
                              onTextKeyPress: _debouncedTextSave,
                            ),
                          ),
                      ArrowWellsOverlay(
                        scale: ref
                            .read(canvasViewportProvider)
                            .value
                            .getMaxScaleOnAxis(),
                        showArrowWells: true,
                        transformationController: viewportController,
                        gestureRouter: _gestureRouter,
                      ),
                      if (showComments)
                        ..._buildComments(
                          comments: comments,
                          objects: objects.objects,
                          transformationController: viewportController,
                        ),
                      if (showArtifacts)
                        ...pins.pins.map((pin) {
                          CanvasObject? targetObject;
                          if (pin.pinnedObjectId != null) {
                            targetObject = objects.objects.firstWhereOrNull(
                              (obj) => obj.id == pin.pinnedObjectId,
                            );
                          }

                          return CanvasPin(
                            pin: pin,
                            canvasObject: targetObject,
                            position: pin.getOffset(parent: targetObject),
                            transformationController: viewportController,
                            isExpanded: _isPinExpanded(pin.id),
                            onTap: () => _isPinExpanded(pin.id)
                                ? _collapsePin()
                                : _expandPin(pin),
                          );
                        }),
                      if (showArtifacts)
                        _buildExpandedItem(
                          comments: comments,
                          pins: pins.pins,
                          objects: objects.objects,
                          transformationController: viewportController,
                        ),
                      DragTarget<TreeNode>(
                        onWillAcceptWithDetails: (data) => true,
                        onAcceptWithDetails: (details) {
                          final RenderBox renderBox =
                              context.findRenderObject() as RenderBox;
                          final canvasPosition = renderBox.globalToLocal(
                            details.offset,
                          );

                          final hitInteractionContext = _canvasPainter
                              ?.hitTestForDropEvent(canvasPosition);
                          final hitObjectFill =
                              hitInteractionContext
                                  is ObjectFillInteractionContext;

                          if (hitObjectFill ||
                              config.allowArtifactsOnBackground) {
                            // Hit an object - create pin on the object
                            switch (config.artifactDisplay) {
                              case .pin:
                                CanvasInteractionService.createPin(
                                  ref: ref,
                                  position: canvasPosition,
                                  onExpand: _expandPin,
                                  item: details.data.data,
                                  targetObject: hitObjectFill
                                      ? hitInteractionContext.targetObject
                                      : null,
                                );
                                break;
                              case .object:
                                CanvasInteractionService.createArtifactObject(
                                  ref: ref,
                                  position: canvasPosition,
                                  artifact: details.data.data,
                                );
                                break;
                            }
                          } else {
                            OnyxiaToast.show(
                              text:
                                  'Cannot drop item pins on whiteboard canvas.',
                              type: .info,
                            );
                          }
                        },
                        builder: (context, candidateData, rejectedData) =>
                            const SizedBox.expand(),
                      ),
                      DragTarget<Object>(
                        onWillAcceptWithDetails: (data) =>
                            data.data is ImageDragData,
                        onAcceptWithDetails: (details) {
                          final RenderBox renderBox =
                              context.findRenderObject() as RenderBox;
                          final canvasPosition = renderBox.globalToLocal(
                            details.offset,
                          );
                          if (details.data is ImageDragData) {
                            CanvasInteractionService.insertImage(
                              ref: ref,
                              data: details.data as ImageDragData,
                              canvasPosition: canvasPosition,
                            );
                          }
                        },
                        builder: (context, candidateData, rejectedData) =>
                            const SizedBox.expand(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtifactDragFeedback(BuildContext context) {
    const double spacing = CanvasBounds.gridSpacing;
    const double width = spacing * 10;
    const double height = spacing * 10;

    return Transform.translate(
      offset: Offset(-width / 2, -height / 2),
      child: Material(
        elevation: 4,
        borderRadius: .circular(8),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: ThemeHelper.neutral200(context),
            borderRadius: .circular(8),
            border: .all(color: ThemeHelper.neutral400(context), width: 1.5),
          ),
        ),
      ),
    );
  }

  /// Build expanded item widget for the currently expanded item (pin or comment)
  Widget _buildExpandedItem({
    required List<Comment> comments,
    required List<Pin> pins,
    required List<CanvasObject> objects,
    required TransformationController transformationController,
  }) {
    final expandedItem = _expandedPin;
    if (expandedItem == null) return const SizedBox.shrink();

    // Check if expanded item is a pin
    final pin = pins.firstWhereOrNull((p) => p.id == expandedItem.id);
    if (pin != null) {
      CanvasObject? targetObject;
      if (pin.pinnedObjectId != null) {
        targetObject = objects.firstWhereOrNull(
          (obj) => obj.id == pin.pinnedObjectId,
        );
      }

      return CanvasPinExpanded(
        key: ValueKey('expanded_${pin.id}'),
        pin: pin,
        canvasObject: targetObject,
        pinPosition: pin.getOffset(parent: targetObject),
        transformationController: transformationController,
        onClose: _collapsePin,
        onRemovePin: () {
          _collapsePin();
          ref.read(pinsProvider.notifier).deletePin(pin);
        },
      );
    }

    // Check if expanded item is a comment
    final comment = comments.firstWhereOrNull((c) => c.id == expandedItem.id);
    if (comment != null) {
      CanvasObject? obj = comment.pinnedObjectId != null
          ? ref
                .read(canvasObjectsProvider.notifier)
                .getObjectById(comment.pinnedObjectId!)
          : null;

      return CanvasCommentPinExpanded(
        key: ValueKey('expanded_comment_${comment.id}'),
        comment: comment,
        canvasObject: obj,
        position: comment.getOffset(parent: obj),
        transformationController: transformationController,
        onClose: _collapsePin,
        onDeleteComment: () => ref
            .read(commentsProvider.notifier)
            .deleteComment(commentId: comment.id),
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget> _buildComments({
    required List<Comment> comments,
    required List<CanvasObject> objects,
    required TransformationController transformationController,
  }) => comments.map((comment) {
    CanvasObject? targetObject;
    if (comment.pinnedObjectId != null) {
      targetObject = objects.firstWhereOrNull(
        (obj) => obj.id == comment.pinnedObjectId,
      );
    }

    return CanvasCommentPin(
      transformationController: transformationController,
      comment: comment,
      canvasObject: targetObject,
      position: comment.getOffset(parent: targetObject),
      isExpanded: _isPinExpanded(comment.id),
      onTap: () =>
          _isPinExpanded(comment.id) ? _collapsePin() : _expandPin(comment),
    );
  }).toList();

  Widget _buildImageDropRegion(WidgetRef ref) {
    final config = ref.watch(canvasConfigProvider);

    // Only build file drop region if allowed by config
    if (!config.allowFileDrops) return const SizedBox.shrink();

    return Positioned.fill(
      child: DropRegion(
        formats: [
          Formats.png,
          Formats.jpeg,
          Formats.gif,
          Formats.bmp,
          Formats.webp,
        ],
        hitTestBehavior: .translucent,
        onDropOver: (event) {
          _isDragHovering.value = true;
          return event.session.allowedOperations.firstOrNull ??
              DropOperation.none;
        },
        onDropLeave: (event) {
          _isDragHovering.value = false;
        },
        onPerformDrop: (event) => _handleFileDrop(ref, event),
        child: ValueListenableBuilder<bool>(
          valueListenable: _isDragHovering,
          builder: (context, isDragHovering, child) {
            if (!isDragHovering) return const SizedBox.expand();

            return Container(
              color: ThemeHelper.blue400(context).withValues(alpha: 0.5),
              padding: .all(16),
              child: DottedBorder(
                borderType: .RRect,
                radius: .circular(8),
                color: ThemeHelper.white(context).withValues(alpha: 0.7),
                strokeWidth: 4,
                dashPattern: const [8, 4],
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: .circular(8),
                  ),
                  width: .infinity,
                  height: .infinity,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static const _imageFormats = [
    Formats.png,
    Formats.jpeg,
    Formats.gif,
    Formats.bmp,
    Formats.webp,
  ];

  Future<void> _handleFileDrop(WidgetRef ref, PerformDropEvent event) async {
    _isDragHovering.value = false;

    if (!ref.read(canvasConfigProvider).allowFileDrops) return;

    final validFiles = (await Future.wait(
      event.session.items.map(_readDroppedItem),
    )).whereType<PlatformFile>().toList();

    if (validFiles.isEmpty) {
      OnyxiaToast.show(text: 'No valid image files found', type: .error);
      return;
    }

    if (!mounted) return;
    CanvasImageUploadService.uploadAndPlaceImages(
      ref: ref,
      context: context,
      files: validFiles,
    );
  }

  Future<PlatformFile?> _readDroppedItem(DropItem item) async {
    final reader = item.dataReader!;
    final format = _imageFormats.firstWhereOrNull(reader.canProvide);
    if (format == null) return null;

    final completer = Completer<DataReaderFile>();
    reader.getFile(
      format,
      completer.complete,
      onError: completer.completeError,
    );
    final file = await completer.future;
    final bytes = await file.readAll();

    if (bytes.length >= 600 * 1024) return null;
    return PlatformFile(
      name: file.fileName ?? 'image.png',
      size: bytes.length,
      bytes: bytes,
    );
  }
}
