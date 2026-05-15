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
  bool _showShapesSubmenu = false;

  // Comprehensive mapping of all tools to their icons
  static const Map<ToolMode, IconData> _toolIcons = {
    // Basic tools
    ToolMode.pointer: LucideIcons.mousePointer,
    ToolMode.pan: LucideIcons.move,

    // Shape tools
    ToolMode.rectangle: LucideIcons.square,
    ToolMode.diamond: LucideIcons.diamond,
    ToolMode.oblong: LucideIcons.rectangleHorizontal,
    ToolMode.circle: LucideIcons.circle,
    ToolMode.rhombus: LucideIcons.diamond,
    ToolMode.trapezoid: LucideIcons.pentagon,
    ToolMode.cylinder: LucideIcons.cylinder,
    ToolMode.house: LucideIcons.house,
    ToolMode.reverseHouse: LucideIcons.house,

    // Other tools
    ToolMode.arrow: LucideIcons.minus,
    ToolMode.image: LucideIcons.image,
    ToolMode.text: LucideIcons.type,
    ToolMode.brush: LucideIcons.penTool,
    ToolMode.comment: LucideIcons.messageSquare,
    ToolMode.artifact: LucideIcons.fileText,
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
    ref.read(toolModeProvider.notifier).set(toolMode);
    setState(() => _showShapesSubmenu = false);
  }

  void _toggleShapesSubmenu() {
    ref.read(canvasObjectsProvider.notifier).clearSelectedObjects();
    widget.closeTextEditor();
    setState(() => _showShapesSubmenu = !_showShapesSubmenu);
  }

  @override
  Widget build(BuildContext context) {
    final selectedTool = ref.watch(toolModeProvider);
    final config = ref.watch(canvasConfigProvider);

    return Stack(
      children: [
        _buildMainToolBar(selectedTool, config),
        if (_showShapesSubmenu && _hasShapeTools(config))
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
          icon: LucideIcons.pentagon,
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
                  .set(true);
              _onToolSelected(ToolMode.pointer);
            } else {
              // If artifact tool is not selected, select it and show tree drawer
              _onToolSelected(ToolMode.artifact);
              ref
                  .read(canvasSettingsProvider(Setting.showMinimap).notifier)
                  .set(false);
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
