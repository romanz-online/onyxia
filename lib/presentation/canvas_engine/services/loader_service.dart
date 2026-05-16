import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'interaction_service.dart';

import 'loader_paste_listener.dart';

/// Service responsible for loading and initializing canvas screens
/// Provides centralized initialization logic for both whiteboard and markup screens
class CanvasLoaderService {
  // Internal state management for current canvas
  static bool Function(KeyEvent)? _currentKeyboardHandler;
  static PasteListenerHandle? _pasteListener;

  static void setupCanvas({
    required WidgetRef ref,
    required String canvasId,
    required BuildContext context,
    required VoidCallback onCollapsePin,
  }) {
    // Reset state for new canvas

    // Setup keyboard handler (wraps async handleKeyEvent)
    _currentKeyboardHandler = (event) {
      CanvasInteractionService.handleKeyEvent(
        event: event,
        ref: ref,
        context: context,
        onCollapsePin: onCollapsePin,
      );
      return false; // Return false to allow other handlers to process if needed
    };
    HardwareKeyboard.instance.addHandler(_currentKeyboardHandler!);

    _pasteListener = setupPasteListenerImpl(ref, context);

    // Setup canvas initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;

      final vaultId = ref.read(selectedVaultProvider)?.id;
      if (vaultId == null) return;

      initCanvas(ref: ref, context: context, canvasId: canvasId);
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
  }

  static Future<void> initCanvas({
    required WidgetRef ref,
    required BuildContext context,
    required String canvasId,
  }) async {
    if (!context.mounted) return;

    final selected = ref.read(selectedArtifactProvider);
    final CanvasArtifact? currentCanvas =
        selected is CanvasArtifact ? selected : null;

    final vaultId = ref.read(selectedVaultProvider)?.id;
    if (vaultId == null) return;

    // Loader service owns the full initialization sequence.
    // Always reinitialize bounds to guarantee correct state on every canvas entry.
    await ref
        .read(canvasBoundsProvider.notifier)
        .initializeBounds(currentCanvas);

    if (!context.mounted) return;

    // Center the viewport directly — bounds are guaranteed ready at this point
    ref.read(canvasViewportProvider.notifier).centerViewport(context);
  }
}
