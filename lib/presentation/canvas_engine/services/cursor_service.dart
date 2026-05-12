import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'dart:convert';

/// Service for managing custom canvas cursors using SVG via CSS url() on web.
class CanvasCursorService {
  // Singleton instance
  static final CanvasCursorService instance = CanvasCursorService._();
  CanvasCursorService._();

  bool _isLoaded = false;
  MouseCursor _currentSystemCursor = MouseCursor.defer;
  String? _currentCssCursor;
  final Map<String, String> _svgDataUriCache = {};

  MouseCursor get currentSystemCursor => _currentSystemCursor;
  String? get currentCssCursor => _currentCssCursor;

  // ========== Web Cursor Paths (SVG) ==========
  static const String _cursorBasicSvg = 'assets/icons/Cursor_Default.svg';
  static const String _cursorHandSvg = 'assets/icons/Hand_Default.svg';
  static const String _cursorHandGrabbingSvg = 'assets/icons/Hand_Grabbing.svg';
  static const String _diagramCursorSvg =
      'assets/icons/DiagramCursor_Default.svg';
  static const String _diagramCursorCommentSvg =
      'assets/icons/DiagramCursor_Comment.svg';
  static const String _diagramCursorArtifactSvg =
      'assets/icons/DiagramCursor_Requirement.svg';

  // ========== Tool Mode Cursors ==========
  // Format: (regularPath, pressedPath, hotspotX, hotspotY)
  static final Map<ToolMode, (String, String?, int, int)> _toolCursorsWeb = {
    ToolMode.pointer: (_cursorBasicSvg, null, 0, 0),
    ToolMode.pan: (_cursorHandSvg, _cursorHandGrabbingSvg, 12, 12),
    ToolMode.comment: (_diagramCursorCommentSvg, null, 12, 12),
    ToolMode.artifact: (_diagramCursorArtifactSvg, null, 12, 12),
    ToolMode.rectangle: (_diagramCursorSvg, null, 12, 12),
    ToolMode.diamond: (_diagramCursorSvg, null, 12, 12),
    ToolMode.oblong: (_diagramCursorSvg, null, 12, 12),
    ToolMode.circle: (_diagramCursorSvg, null, 12, 12),
    ToolMode.rhombus: (_diagramCursorSvg, null, 12, 12),
    ToolMode.trapezoid: (_diagramCursorSvg, null, 12, 12),
    ToolMode.cylinder: (_diagramCursorSvg, null, 12, 12),
    ToolMode.house: (_diagramCursorSvg, null, 12, 12),
    ToolMode.reverseHouse: (_diagramCursorSvg, null, 12, 12),
    ToolMode.text: (_diagramCursorSvg, null, 12, 12),
    ToolMode.image: (_diagramCursorSvg, null, 12, 12),
    ToolMode.media: (_diagramCursorSvg, null, 12, 12),
    ToolMode.brush: (_diagramCursorSvg, null, 12, 12),
    ToolMode.arrow: (_diagramCursorSvg, null, 12, 12),
  };

  // ========== System Cursor Overrides ==========
  // Note: resizeUpDown and resizeLeftRight use native system cursors (no override)
  static final Map<MouseCursor, (String, String?, int, int)>
      _systemCursorOverridesWeb = {
    SystemMouseCursors.basic: (_cursorBasicSvg, null, 12, 12),
    SystemMouseCursors.grab: (_cursorHandSvg, _cursorHandGrabbingSvg, 12, 12),
    SystemMouseCursors.grabbing: (_cursorHandGrabbingSvg, null, 12, 12),
    SystemMouseCursors.cell: (_diagramCursorSvg, null, 12, 12),
  };

  Future<void> loadCursors() async {
    if (_isLoaded) return;
    final Set<String> svgPaths = {};
    for (final data in _toolCursorsWeb.values) {
      svgPaths.add(data.$1);
      if (data.$2 != null) svgPaths.add(data.$2!);
    }
    for (final data in _systemCursorOverridesWeb.values) {
      svgPaths.add(data.$1);
      if (data.$2 != null) svgPaths.add(data.$2!);
    }
    for (final path in svgPaths) {
      final svgContent = await rootBundle.loadString(path);
      final base64Svg = base64Encode(utf8.encode(svgContent));
      _svgDataUriCache[path] = 'data:image/svg+xml;base64,$base64Svg';
    }
    _isLoaded = true;
  }

  void updateCursors(ToolMode toolMode, bool isPressed, MouseCursor? override) {
    _currentCssCursor = _resolveCssForCursor(toolMode, isPressed, override);
    _currentSystemCursor = (_currentCssCursor != null)
        ? MouseCursor.defer
        : (override ?? SystemMouseCursors.cell);
  }

  String? _resolveCssForCursor(
    ToolMode toolMode,
    bool isPressed,
    MouseCursor? override,
  ) {
    final svgData = _systemCursorOverridesWeb[override];
    if (svgData != null) {
      String path = isPressed ? (svgData.$2 ?? svgData.$1) : svgData.$1;
      final uri = _svgDataUriCache[path] ?? path;
      return 'url($uri) ${svgData.$3} ${svgData.$4}, auto';
    }

    if (override == null) {
      final toolData =
          _toolCursorsWeb[toolMode] ?? _toolCursorsWeb[ToolMode.pointer]!;
      String path = isPressed ? (toolData.$2 ?? toolData.$1) : toolData.$1;
      final uri = _svgDataUriCache[path] ?? path;
      return 'url($uri) ${toolData.$3} ${toolData.$4}, auto';
    }

    return null;
  }
}
