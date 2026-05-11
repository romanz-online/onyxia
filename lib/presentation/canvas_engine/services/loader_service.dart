import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'cursor_service.dart';
import 'interaction_service.dart';

import 'loader_paste_listener.dart';

/// Service responsible for loading and initializing canvas screens
/// Provides centralized initialization logic for both whiteboard and markup screens
class CanvasLoaderService {
  // Internal state management for current canvas
  // static bool _hasReceivedInitialDiffs = false;
  static bool Function(KeyEvent)? _currentKeyboardHandler;
  static final CanvasCursorService _cursorManager =
      CanvasCursorService.instance;
  static PasteListenerHandle? _pasteListener;

  static void setupCanvas({
    required WidgetRef ref,
    required String canvasId,
    required BuildContext context,
  }) {
    // Reset state for new canvas
    // _hasReceivedInitialDiffs = false;

    // Setup keyboard handler (wraps async handleKeyEvent)
    _currentKeyboardHandler = (event) {
      CanvasInteractionService.handleKeyEvent(
        event: event,
        ref: ref,
        context: context,
      );
      return false; // Return false to allow other handlers to process if needed
    };
    HardwareKeyboard.instance.addHandler(_currentKeyboardHandler!);

    _pasteListener = setupPasteListenerImpl(ref, context);

    // Setup canvas initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;

      final projectId = ref.read(projectsProvider).selectedProject?.id;
      if (projectId == null) return;

      initCanvas(ref: ref, context: context, canvasId: canvasId);

      // Listen for the first diffs callback, then initialize
      // final params = HistoryDiffsParams(
      //   projectId: projectId,
      //   itemId: canvasId,
      //   itemType: ArtifactType.canvas,
      // );
      // ref.listenManual(historyDiffsProvider(params), (previous, next) {
      //   if (!_hasReceivedInitialDiffs) {
      //     _hasReceivedInitialDiffs = true;
      //     initCanvas(ref: ref, context: context, canvasId: canvasId);
      //   }
      // });
    });
  }

  /// Cleans up canvas resources (replaces dispose logic)
  static void cleanupCanvas({required BuildContext context}) {
    // Remove keyboard handler
    if (_currentKeyboardHandler != null) {
      HardwareKeyboard.instance.removeHandler(_currentKeyboardHandler!);
      _currentKeyboardHandler = null;
    }

    removePasteListenerImpl(_pasteListener);

    // Reset state
    // _hasReceivedInitialDiffs = false;
  }

  static Future<void> initCanvas({
    required WidgetRef ref,
    required BuildContext context,
    required String canvasId,
  }) async {
    if (!context.mounted) return;

    CanvasArtifact? currentCanvas = ref.read(currentCanvasProvider);

    final projectId = ref.read(projectsProvider).selectedProject?.id;
    if (projectId == null) return;

    // add initial diff if this is the first time the canvas is being loaded
    // only check after we've received the initial Firebase stream callback
    // final params = HistoryDiffsParams(
    //   projectId: projectId,
    //   itemId: canvasId,
    //   itemType: ArtifactType.canvas,
    // );
    // if (_hasReceivedInitialDiffs &&
    //     ref.read(historyDiffsProvider(params)).remoteDiffs.isEmpty) {
    //   HistoryService.initHistory(
    //     ref: ref,
    //     projectId: projectId,
    //     serializer: CanvasSerializerService(
    //       canvasId: canvasId,
    //       projectId: projectId,
    //       repository: ArtifactsRepository(projectId: projectId),
    //     ),
    //   );
    // }

    // Loader service owns the full initialization sequence.
    // Always reinitialize bounds to guarantee correct state on every canvas entry.
    ref.read(canvasBoundsProvider.notifier).initializeBounds(currentCanvas);

    // Wait for bounds to finish loading (markup canvases load an image asynchronously)
    while (ref.read(canvasBoundsProvider).isLoading && context.mounted) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    if (!context.mounted) return;

    await _cursorManager.loadCursors();

    if (!context.mounted) return;

    // Center the viewport directly — bounds are guaranteed ready at this point
    ref.read(canvasViewportProvider.notifier).centerViewport(context);

    if (!context.mounted) return;

    // ref.read(canvasDiffPreviewProvider.notifier).clearPreview();
  }
}
