import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'package:web/web.dart' as web;

class CanvasCursorOverlay extends ConsumerWidget {
  final Widget child;
  final _cursorService = CanvasCursorService.instance;

  CanvasCursorOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolMode = ref.watch(toolModeProvider);
    final isPressed = ref.watch(canvasMousePressedProvider);
    final override = ref.watch(cursorIconOverrideProvider);

    _cursorService.updateCursors(toolMode, isPressed, override);
    // apply the cursor immediately, otherwise some events get lost
    if (kIsWeb && _cursorService.currentCssCursor != null && web.document.body != null) {
      web.document.body!.style.cursor = _cursorService.currentCssCursor!;
    }

    return MouseRegion(
      cursor: _cursorService.currentSystemCursor,
      hitTestBehavior: HitTestBehavior.translucent,
      onHover: (event) {
        if (kIsWeb && _cursorService.currentCssCursor != null && web.document.body != null) {
          web.document.body!.style.cursor = _cursorService.currentCssCursor!;
        }
      },
      onExit: (event) {
        if (kIsWeb && web.document.body != null) {
          web.document.body!.style.cursor = 'default';
        }
      },
      child: child,
    );
  }
}
