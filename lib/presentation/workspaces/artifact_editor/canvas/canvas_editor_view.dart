import 'package:onyxia/export.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/canvas_pin.dart';
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
import 'package:onyxia/presentation/canvas_engine/widgets/minimap.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/painter/canvas_painter.dart';
import 'package:onyxia/presentation/canvas_engine/widgets/toolbar.dart';
import 'package:onyxia/presentation/canvas_engine/canvas_config.dart';
import 'package:onyxia/presentation/canvas_engine/utils/image_drag_data.dart';
import 'dart:async';

final isDragHoveringProvider = StateProvider<bool>((ref) => false);

class CanvasEditorView extends ConsumerStatefulWidget {
  final String canvasId;
  final SaveMode saveMode;

  const CanvasEditorView({
    super.key,
    required this.canvasId,
    this.saveMode = SaveMode.auto,
  });

  @override
  ConsumerState<CanvasEditorView> createState() => _CanvasEditorView();
}

class _CanvasEditorView extends ConsumerState<CanvasEditorView> {
  late CanvasGestureRouter _gestureRouter;
  CanvasPainter? _canvasPainter;
  Timer? _textSaveTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      CanvasLoaderService.setupCanvas(
        ref: ref,
        canvasId: widget.canvasId,
        context: context,
      );
    });
  }

  @override
  void dispose() {
    _textSaveTimer?.cancel();
    CanvasLoaderService.cleanupCanvas(context: context);
    super.dispose();
  }

  void _debouncedTextSave(CanvasObject obj) {
    ref.read(canvasObjectsProvider.notifier).updateObjectState(obj);
    _textSaveTimer?.cancel();
    _textSaveTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref.read(canvasObjectsProvider.notifier).updateObject(ref, obj);
    });
  }

  @override
  Widget build(BuildContext context) {
    final urlCanvasId = ref.watch(urlCanvasIdProvider);
    final currentCanvas = ref.watch(currentCanvasProvider);
    final canvasBounds = ref.watch(canvasBoundsProvider);

    // Show spinner while bounds are loading, or while waiting for urlCanvasIdProvider
    // to be set via post-frame callback (there is a 1-frame window between the parent
    // rendering and the callback firing where both are null)
    if (canvasBounds.isLoading ||
        (urlCanvasId == null && currentCanvas == null)) {
      return Scaffold(body: Center(child: NarwhalSpinner()));
    }

    // If canvas is null here, it is definitively not found (urlCanvasId is set but
    // the canvas doesn't exist in the project, or selectedItem is not a canvas)
    if (currentCanvas == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Canvas not found',
            style: NarwhalTextStyle(),
          ),
        ),
      );
    }

    final objects = ref.watch(canvasObjectsProvider);
    final selectedTool = ref.watch(toolModeProvider);
    final objectText = ref.watch(canvasTextProvider);
    final canvasCommentsState = ref.watch(commentsProvider);
    final showArtifacts =
        ref.watch(canvasSettingsProvider(Setting.showArtifacts));
    final showComments =
        ref.watch(canvasSettingsProvider(Setting.showComments));
    final showToolbar = ref.watch(canvasSettingsProvider(Setting.showToolbar));
    final arrowPreview = ref.watch(arrowPreviewProvider);
    final headlessState = ref.watch(headlessProvider);
    final pins = ref.watch(pinsProvider);

    final comments = [
      ...canvasCommentsState.comments,
      if (canvasCommentsState.temporaryComment != null)
        canvasCommentsState.temporaryComment!,
    ];

    // Update gesture router with current context and config
    _gestureRouter = CanvasGestureRouter(
      ref: ref,
      context: context,
      canvasConfig: ref.read(canvasConfigProvider),
    );

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
              if (currentCanvas.canvasType == CanvasType.flow)
                DragOffBar(
                  buttons: [
                    DragOffBarButton(
                      icon: NarwhalIcons.note,
                      dragData: DragOffBarData(type: ArtifactType.note),
                      dragFeedbackBuilder: () =>
                          _buildArtifactDragFeedback(context),
                    ),
                    // DragOffBarButton(
                    //   icon: NarwhalIcons.imageTool,
                    //   dragData: DragOffBarData(type: ArtifactType.canvas),
                    //   dragFeedbackBuilder: () => _buildArtifactDragFeedback(context),
                    // ),
                  ],
                )
              else
                Toolbar(
                  closeTextEditor: () =>
                      CanvasInteractionService.closeTextEditor(ref: ref),
                ),
            if (headlessState.isVisible)
              HeadlessPalette(
                arrow: headlessState.headlessArrow!,
              ),
            Minimap(canvas: currentCanvas),
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
            ref.read(canvasMousePressedProvider.notifier).state = true,
        onPointerUp: (_) =>
            ref.read(canvasMousePressedProvider.notifier).state = false,
        onPointerCancel: (_) =>
            ref.read(canvasMousePressedProvider.notifier).state = false,
        child: InteractiveViewer(
          minScale: ref.read(canvasViewportProvider.notifier).minScale,
          maxScale: ref.read(canvasViewportProvider.notifier).maxScale,
          transformationController: viewportController,
          boundaryMargin: EdgeInsets.all(0.0),
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
                      CustomPaint(
                        size: canvasBounds.size,
                        child: CanvasTouchDetector(
                          gesturesToOverride: [
                            GestureType.onTapDown,
                            GestureType.onTapUp,
                            // onPanDown breaks things because it triggers at the same time as regular taps
                            // GestureType.onPanDown,
                            if (!_gestureRouter.allowsViewportPanning) ...[
                              // if statement allows InteractiveViewer to handle viewport panning when needed
                              GestureType.onPanStart,
                              GestureType.onPanUpdate,
                              GestureType.onPanEnd,
                            ],
                            GestureType.onSecondaryTapDown,
                            GestureType.onSecondaryTapUp,
                            GestureType.onHover,
                          ],
                          builder: (context) {
                            _canvasPainter = CanvasPainter(
                              ref: ref,
                              context: context,
                              gestureRouter: _gestureRouter,
                              objects: objects.objects,
                              selectedObjects: objects.selectedObjects,
                              draggedObjects: ref.watch(draggedObjectsProvider),
                              dragSelect:
                                  ref.watch(dragSelectProvider).dragRect,
                              arrowPrimedObjects:
                                  ref.watch(arrowPrimedObjectsProvider),
                              arrowToolPrimedData:
                                  ref.watch(arrowToolPrimedObjectsProvider),
                              textEditedObjId:
                                  ref.watch(canvasTextProvider).editingObjId,
                              arrowPreview: arrowPreview,
                            );

                            return CustomPaint(
                              size: canvasBounds.size,
                              painter: _canvasPainter,
                            );
                          },
                        ),
                      ),
                      ...objects.objects.where((e) => !e.isArrow).map(
                            (obj) => CanvasObjectTextArea(
                              context: context,
                              canvasObject: obj,
                              gestureRouter: _gestureRouter,
                              objectTextState: objectTextState,
                              onTextKeyPress: _debouncedTextSave,
                            ),
                          ),
                      ...objects.objects.where((e) => e.isArrow).map(
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
                        ...pins.pins.map(
                          (pin) {
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
                            );
                          },
                        ),
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
                          final canvasPosition =
                              renderBox.globalToLocal(details.offset);

                          final hitInteractionContext = _canvasPainter
                              ?.hitTestForDropEvent(canvasPosition);
                          final hitObjectFill = hitInteractionContext
                              is ObjectFillInteractionContext;

                          if (hitObjectFill ||
                              config.allowArtifactsOnBackground) {
                            // Hit an object - create pin on the object
                            switch (config.artifactDisplay) {
                              case ArtifactCanvasDisplay.pin:
                                CanvasInteractionService.createPin(
                                  ref: ref,
                                  position: canvasPosition,
                                  item: details.data.data,
                                  targetObject: hitObjectFill
                                      ? hitInteractionContext.targetObject
                                      : null,
                                );
                                break;
                              case ArtifactCanvasDisplay.object:
                                CanvasInteractionService.createArtifactObject(
                                  ref: ref,
                                  position: canvasPosition,
                                  artifact: details.data.data,
                                );
                                break;
                            }
                          } else {
                            NarwhalToast.show(
                              text:
                                  'Cannot drop item pins on whiteboard canvas.',
                              type: ToastType.info,
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
                          final canvasPosition =
                              renderBox.globalToLocal(details.offset);
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
                      DragTarget<DragOffBarData>(
                        onWillAcceptWithDetails: (data) => true,
                        onAcceptWithDetails: (details) {
                          final RenderBox renderBox =
                              context.findRenderObject() as RenderBox;
                          final canvasPosition =
                              renderBox.globalToLocal(details.offset);

                          // Handle rectangle drag and drop
                          if (details.data.type == ArtifactType.note) {
                            // Store the drop position
                            ref
                                .read(dragOffDropPositionProvider.notifier)
                                .state = canvasPosition;
                            // Open the search overlay
                            ref
                                .read(canvasSettingsProvider(
                                        Setting.showSearchOverlay)
                                    .notifier)
                                .state = true;
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: ThemeHelper.neutral200(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ThemeHelper.neutral400(context),
              width: 1.5,
            ),
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
    final expandedItem = ref.watch(expandedPinProvider);
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
        onRemovePin: () => CanvasInteractionService.deletePin(
          ref: ref,
          pin: pin,
          parentObject: targetObject,
        ),
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
        onDeleteComment: () => CanvasInteractionService.deleteComment(
          ref: ref,
          commentId: comment.id,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget> _buildComments({
    required List<Comment> comments,
    required List<CanvasObject> objects,
    required TransformationController transformationController,
  }) =>
      comments.map((comment) {
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
        hitTestBehavior: HitTestBehavior.translucent,
        onDropOver: (event) {
          ref.read(isDragHoveringProvider.notifier).state = true;
          return event.session.allowedOperations.firstOrNull ??
              DropOperation.none;
        },
        onDropLeave: (event) {
          ref.read(isDragHoveringProvider.notifier).state = false;
        },
        onPerformDrop: (event) => _handleFileDrop(ref, event),
        child: Consumer(
          builder: (context, ref, child) {
            final isDragHovering = ref.watch(isDragHoveringProvider);

            if (!isDragHovering) return const SizedBox.expand();

            return Container(
              color: ThemeHelper.blue400(context).withValues(alpha: 0.5),
              padding: const EdgeInsets.all(16),
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(8),
                color: ThemeHelper.white(context).withValues(alpha: 0.7),
                strokeWidth: 4,
                dashPattern: const [8, 4],
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleFileDrop(WidgetRef ref, PerformDropEvent event) async {
    // Reset drag hovering state
    ref.read(isDragHoveringProvider.notifier).state = false;

    final config = ref.watch(canvasConfigProvider);

    // Check if file drops are allowed for this canvas config
    if (!config.allowFileDrops) {
      return;
    }

    final imageFormats = [
      Formats.png,
      Formats.jpeg,
      Formats.gif,
      Formats.bmp,
      Formats.webp,
    ];

    final validFiles = <PlatformFile>[];
    int itemsProcessed = 0;
    final totalItems = event.session.items.length;

    void checkIfAllProcessed() {
      if (itemsProcessed == totalItems) {
        if (validFiles.isEmpty) {
          NarwhalToast.show(
            text: 'No valid image files found',
            type: ToastType.error,
          );
          return;
        }
        CanvasImageUploadService.uploadAndPlaceImages(
          ref: ref,
          context: context,
          files: validFiles,
        );
      }
    }

    // Process each dropped item
    for (final item in event.session.items) {
      final reader = item.dataReader!;

      // Check if any image format is available
      FileFormat? format;
      for (final f in imageFormats) {
        if (reader.canProvide(f)) {
          format = f;
          break;
        }
      }

      if (format != null) {
        try {
          reader.getFile(
            format,
            (file) {
              final future = file.readAll();
              future.then((data) {
                // Check file size (600KB limit)
                if (data.length < 600 * 1024) {
                  final platformFile = PlatformFile(
                    name: file.fileName ?? 'image.png',
                    size: data.length,
                    bytes: data,
                  );
                  validFiles.add(platformFile);
                }
                itemsProcessed++;
                checkIfAllProcessed();
              }).catchError((e) {
                debugPrint('Error reading file data: $e');
                NarwhalToast.show(
                  text: 'Error reading file data: $e',
                  type: ToastType.error,
                );
                itemsProcessed++;
                checkIfAllProcessed();
              });
            },
            onError: (error) {
              debugPrint('Error reading dropped file: $error');
              NarwhalToast.show(
                text: 'Error reading dropped file: $error',
                type: ToastType.error,
              );
              itemsProcessed++;
              checkIfAllProcessed();
            },
          );
        } catch (e) {
          debugPrint('Error reading dropped file: $e');
          NarwhalToast.show(
            text: 'Error reading dropped file: $e',
            type: ToastType.error,
          );
          itemsProcessed++;
          checkIfAllProcessed();
        }
      } else {
        itemsProcessed++;
        checkIfAllProcessed();
      }
    }
  }
}
