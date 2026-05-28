import 'package:onyxia/export.dart';
import '../providers/providers.dart';

/// Service for managing canvas cursors. Currently uses native system cursors;
/// the prior custom-SVG cursor implementation was removed with the icon migration.
class CanvasCursorService {
  static final CanvasCursorService instance = CanvasCursorService._();
  CanvasCursorService._();

  MouseCursor _currentSystemCursor = MouseCursor.defer;

  MouseCursor get currentSystemCursor => _currentSystemCursor;

  void updateCursors(ToolMode toolMode, bool isPressed, MouseCursor? override) {
    _currentSystemCursor =
        override ?? _systemCursorForTool(toolMode, isPressed);
  }

  MouseCursor _systemCursorForTool(ToolMode toolMode, bool isPressed) {
    switch (toolMode) {
      case ToolMode.pointer:
        return SystemMouseCursors.basic;
      case ToolMode.pan:
        return isPressed
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.grab;
      default:
        return SystemMouseCursors.cell;
    }
  }
}
