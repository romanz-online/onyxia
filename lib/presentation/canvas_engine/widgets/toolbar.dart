import 'package:onyxia/export.dart';
import '../canvas_config.dart';
import '../providers/providers.dart';

class Toolbar extends ConsumerStatefulWidget {
  final Function closeTextEditor;

  const Toolbar({
    super.key,
    required this.closeTextEditor,
  });

  @override
  ConsumerState<Toolbar> createState() => ToolBarWidgetState();
}

class ToolBarWidgetState extends ConsumerState<Toolbar> {
  // Comprehensive mapping of all tools to their icons
  static const Map<ToolMode, NarwhalIcons> _toolIcons = {
    // Basic tools
    ToolMode.pointer: NarwhalIcons.cursor,
    ToolMode.pan: NarwhalIcons.hand,

    // Shape tools
    ToolMode.rectangle: NarwhalIcons.rectangle,
    ToolMode.diamond: NarwhalIcons.diamond,
    ToolMode.oblong: NarwhalIcons.roundedRectangle,
    ToolMode.circle: NarwhalIcons.circle,
    ToolMode.rhombus: NarwhalIcons.rhombus,
    ToolMode.trapezoid: NarwhalIcons.trapezoid,
    ToolMode.cylinder: NarwhalIcons.cylinder,
    ToolMode.house: NarwhalIcons.pentahome,
    ToolMode.reverseHouse: NarwhalIcons.pentahomeReversed,

    // Other tools
    ToolMode.arrow: NarwhalIcons.line,
    ToolMode.image: NarwhalIcons.imageTool,
    ToolMode.text: NarwhalIcons.textTool,
    ToolMode.brush: NarwhalIcons.drawTool,
    ToolMode.comment: NarwhalIcons.comment,
    ToolMode.artifact: NarwhalIcons.artifact,
  };

  // Get all shape tools in order
  static const List<ToolMode> _shapeTools = [
    ToolMode.rectangle,
    ToolMode.diamond,
    ToolMode.oblong,
    ToolMode.circle,
    ToolMode.rhombus,
    ToolMode.trapezoid,
    ToolMode.cylinder,
    ToolMode.house,
    ToolMode.reverseHouse,
  ];

  // --- Helper methods ---

  bool _isShapeTool(ToolMode? tool) =>
      tool != null && _shapeTools.contains(tool);

  bool _hasShapeTools(CanvasConfig config) =>
      config.toolbar.any((tool) => _isShapeTool(tool));

  BoxDecoration _getPanelDecoration() {
    return BoxDecoration(
      color: ThemeHelper.neutral100(context),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ThemeHelper.neutral400(context), width: 1),
      boxShadow: [
        BoxShadow(
          color: ThemeHelper.neutral900(context).withValues(alpha: 0.1),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  BoxDecoration _getShapesSubMenuDecoration() {
    return BoxDecoration(
      color: ThemeHelper.neutral100(context),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ThemeHelper.neutral400(context), width: 1),
      boxShadow: [
        BoxShadow(
          color: ThemeHelper.neutral900(context).withValues(alpha: 0.1),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 1,
      height: 24,
      color: ThemeHelper.neutral300(context),
    );
  }

  // --- Event and state handling methods ---

  void _onToolSelected(ToolMode toolMode) {
    ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
    widget.closeTextEditor();
    ref.read(toolModeProvider.notifier).state = toolMode;
    ref.read(toolbarStateProvider.notifier).hideSubmenu();
  }

  void _toggleShapesSubmenu() {
    ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
    widget.closeTextEditor();
    ref.read(toolbarStateProvider.notifier).toggleShapesSubmenu();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTool = ref.watch(toolModeProvider);
    final toolbarState = ref.watch(toolbarStateProvider);
    final config = ref.watch(canvasConfigProvider);

    // Cursor automatically updates via CustomCursorOverlay watching toolModeProvider

    return Stack(
      children: [
        _buildMainToolBar(selectedTool, config),
        if (toolbarState.showShapesSubmenu && _hasShapeTools(config))
          _buildShapesSubMenu(config),
      ],
    );
  }

  Widget _buildMainToolBar(ToolMode selectedTool, CanvasConfig config) {
    final iconSize = 30.0;
    final availableTools = config.toolbar;
    List<Widget> toolButtons = [];
    bool shapesButtonAdded = false;

    for (int i = 0; i < availableTools.length; i++) {
      final tool = availableTools[i];

      // Handle null values as dividers
      if (tool == null) {
        if (toolButtons.isNotEmpty) {
          toolButtons.add(const Gap(8));
          toolButtons.add(_buildSeparator());
        }
        continue;
      }

      // Add shapes button when we encounter the first shape tool
      if (_isShapeTool(tool) && !shapesButtonAdded && _hasShapeTools(config)) {
        // Add regular spacing if not empty
        if (toolButtons.isNotEmpty) {
          toolButtons.add(const Gap(8));
        }

        toolButtons.add(NarwhalIconButton(
          icon: NarwhalIcons.shapes,
          size: iconSize,
          onPressed: _toggleShapesSubmenu,
          isSelected: _isShapeTool(selectedTool),
        ));
        shapesButtonAdded = true;
        continue; // Skip individual shape tools
      }

      // shape tools are handled by the shapes button
      if (_isShapeTool(tool)) continue;

      // Add regular spacing between tools
      if (toolButtons.isNotEmpty) {
        toolButtons.add(const Gap(8));
      }

      toolButtons.add(_buildToolButton(tool, selectedTool, iconSize));
    }

    return Positioned.fill(
      bottom: 16,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 56.0,
          decoration: _getPanelDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: toolButtons,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton(
      ToolMode tool, ToolMode selectedTool, double iconSize) {
    final icon = _toolIcons[tool];
    if (icon == null) return const SizedBox.shrink();

    // Handle special cases
    switch (tool) {
      case ToolMode.artifact:
        return NarwhalIconButton(
          icon: icon,
          size: iconSize,
          onPressed: () {
            if (selectedTool == ToolMode.artifact) {
              // If artifact tool is already selected, hide tree drawer and switch to pointer
              ref
                  .read(canvasSettingsProvider(Setting.showMinimap).notifier)
                  .state = true;
              _onToolSelected(ToolMode.pointer);
            } else {
              // If artifact tool is not selected, select it and show tree drawer
              _onToolSelected(ToolMode.artifact);
              ref
                  .read(canvasSettingsProvider(Setting.showMinimap).notifier)
                  .state = false;
            }
          },
          isSelected: selectedTool == tool,
        );
      default:
        return NarwhalIconButton(
          icon: icon,
          size: iconSize,
          onPressed: () => _onToolSelected(tool),
          isSelected: selectedTool == tool,
        );
    }
  }

  Widget _buildShapesSubMenu(CanvasConfig config) {
    final selectedTool = ref.watch(toolModeProvider);
    final availableShapeTools = config.toolbar
        .where((tool) => _isShapeTool(tool))
        .cast<ToolMode>()
        .toList();

    return Positioned.fill(
      bottom: 76,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: _getShapesSubMenuDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < availableShapeTools.length; i++) ...[
                  if (i > 0) const Gap(8),
                  NarwhalIconButton(
                    icon: _toolIcons[availableShapeTools[i]]!,
                    size: 30,
                    onPressed: () => _onToolSelected(availableShapeTools[i]),
                    isSelected: selectedTool == availableShapeTools[i],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
