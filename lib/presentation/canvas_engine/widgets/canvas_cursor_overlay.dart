import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import '../services/services.dart';

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

    return MouseRegion(
      cursor: _cursorService.currentSystemCursor,
      hitTestBehavior: .translucent,
      child: child,
    );
  }
}
