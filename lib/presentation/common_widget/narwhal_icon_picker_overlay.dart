import 'package:onyxia/export.dart';
import 'package:onyxia/helpers/safe_right_click_menu_position.dart';

class NarwhalIconPickerButton extends StatefulWidget {
  final NarwhalIcons selectedIcon;
  final ValueChanged<NarwhalIcons> onIconSelected;

  const NarwhalIconPickerButton({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  State<NarwhalIconPickerButton> createState() => _NarwhalIconPickerButtonState();
}

class _NarwhalIconPickerButtonState extends State<NarwhalIconPickerButton> {
  final GlobalKey _buttonKey = GlobalKey();
  bool _isOverlayOpen = false;

  void _closeOverlay() {
    setState(() {
      _isOverlayOpen = false;
    });
  }

  void _toggleOverlay() {
    setState(() {
      _isOverlayOpen = !_isOverlayOpen;
    });
  }

  Offset? _getButtonPosition() {
    final RenderBox? renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    return renderBox.localToGlobal(Offset.zero);
  }

  Size? _getButtonSize() {
    final RenderBox? renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    return renderBox.size;
  }

  @override
  Widget build(BuildContext context) {
    return NarwhalOverlay(
      isOpen: _isOverlayOpen,
      onClose: _closeOverlay,
      builder: (context, closeOverlay) {
        final buttonPosition = _getButtonPosition();
        final buttonSize = _getButtonSize();

        if (buttonPosition == null || buttonSize == null) return const SizedBox.shrink();

        const double overlayWidth = 400;
        const double overlayHeight = 400;

        // Position overlay so button is at top-right corner
        final desiredPosition = Offset(
          buttonPosition.dx,
          buttonPosition.dy + buttonSize.height + 4, // + padding
        );

        // Keep overlay within screen bounds
        final screenSize = MediaQuery.of(context).size;
        final safePosition = SafeMenuPosition.calculateSafePosition(
          preferredPosition: desiredPosition,
          menuSize: const Size(overlayWidth, overlayHeight),
          screenSize: screenSize,
          padding: 16.0,
        );

        return Positioned(
          left: safePosition.dx,
          top: safePosition.dy,
          child: _NarwhalIconPickerGrid(
            selectedIcon: widget.selectedIcon,
            onIconSelected: (icon) {
              widget.onIconSelected(icon);
              closeOverlay();
            },
          ),
        );
      },
      child: NarwhalIconButton(
        key: _buttonKey,
        icon: widget.selectedIcon,
        onPressed: _toggleOverlay,
        isSelected: _isOverlayOpen,
        iconSafeMode: true,
        // hasCaret: true,
      ),
    );
  }
}

/// The grid of all available NarwhalIcons
class _NarwhalIconPickerGrid extends StatelessWidget {
  final NarwhalIcons selectedIcon;
  final ValueChanged<NarwhalIcons> onIconSelected;

  const _NarwhalIconPickerGrid({
    required this.selectedIcon,
    required this.onIconSelected,
  });

  /// All available NarwhalIcons (172 total)
  static final List<NarwhalIcons> allIcons = [
    NarwhalIcons.twoPaneExpand,
    NarwhalIcons.twoPane,
    NarwhalIcons.aiSparks,
    NarwhalIcons.aiSparksActive,
    NarwhalIcons.addChild,
    NarwhalIcons.addNew,
    NarwhalIcons.add,
    NarwhalIcons.addInverted,
    NarwhalIcons.alignCentered,
    NarwhalIcons.alignLeft,
    NarwhalIcons.alignRight,
    NarwhalIcons.backArrow,
    NarwhalIcons.bold,
    NarwhalIcons.calendar,
    NarwhalIcons.checkBlack,
    NarwhalIcons.check,
    NarwhalIcons.circle,
    NarwhalIcons.closeRemoveTinyDark,
    NarwhalIcons.closeRemoveTinyLight,
    NarwhalIcons.closeRemoveDark,
    NarwhalIcons.closeRemoveLight,
    NarwhalIcons.close,
    NarwhalIcons.colorChip,
    NarwhalIcons.color,
    NarwhalIcons.comment,
    NarwhalIcons.cursor,
    NarwhalIcons.cylinder,
    NarwhalIcons.deSelectAll,
    NarwhalIcons.delete,
    NarwhalIcons.diagramCursor,
    NarwhalIcons.diagramCursorArtifact,
    NarwhalIcons.diagramCursorComment,
    NarwhalIcons.diamond,
    NarwhalIcons.download,
    NarwhalIcons.drawTool,
    NarwhalIcons.dropdownArrow,
    NarwhalIcons.dropdownArrowUp,
    NarwhalIcons.editDefault,
    NarwhalIcons.editWhite,
    NarwhalIcons.edit,
    NarwhalIcons.enter,
    NarwhalIcons.expandArrowCollapsed,
    NarwhalIcons.expandArrowExpanded,
    NarwhalIcons.fieldResize,
    NarwhalIcons.filter,
    NarwhalIcons.folderBlue,
    NarwhalIcons.folderClosed,
    NarwhalIcons.folderFilled,
    NarwhalIcons.folderGreen,
    NarwhalIcons.folderMove,
    NarwhalIcons.folderOpened,
    NarwhalIcons.folderPurple,
    NarwhalIcons.folderRed,
    NarwhalIcons.folderYellow,
    NarwhalIcons.formatClear,
    NarwhalIcons.google,
    NarwhalIcons.gridView,
    NarwhalIcons.hand,
    NarwhalIcons.handGrabbing,
    NarwhalIcons.home,
    NarwhalIcons.imageTool,
    NarwhalIcons.image,
    NarwhalIcons.indent,
    NarwhalIcons.info,
    NarwhalIcons.italic,
    NarwhalIcons.lineCorner,
    NarwhalIcons.lineCurve,
    NarwhalIcons.lineStraight,
    NarwhalIcons.line,
    NarwhalIcons.link,
    NarwhalIcons.listBulleted,
    NarwhalIcons.listNumbered,
    NarwhalIcons.listView,
    NarwhalIcons.minus,
    NarwhalIcons.moreDots,
    NarwhalIcons.noTip,
    NarwhalIcons.pentahomeReversed,
    NarwhalIcons.pentahome,
    NarwhalIcons.placeholder,
    NarwhalIcons.publicGlobeBlack,
    NarwhalIcons.publicGlobeWhite,
    NarwhalIcons.radio,
    NarwhalIcons.rectangle,
    NarwhalIcons.redo,
    NarwhalIcons.noteReq,
    NarwhalIcons.noteSpec,
    NarwhalIcons.noteTest,
    NarwhalIcons.noteUS,
    NarwhalIcons.resolve,
    NarwhalIcons.restore,
    NarwhalIcons.rhombus,
    NarwhalIcons.roundedRectangle,
    NarwhalIcons.search,
    NarwhalIcons.selectAll,
    NarwhalIcons.shapes,
    NarwhalIcons.slash,
    NarwhalIcons.strikethrough,
    NarwhalIcons.strokeDashed,
    NarwhalIcons.strokeDefault,
    NarwhalIcons.strokeThick,
    NarwhalIcons.stroke,
    NarwhalIcons.tableArrowsDown,
    NarwhalIcons.tableArrowsUp,
    NarwhalIcons.team,
    NarwhalIcons.textIndent,
    NarwhalIcons.textSettings,
    NarwhalIcons.textTool,
    NarwhalIcons.textUnIndent,
    NarwhalIcons.tipArrowLeft,
    NarwhalIcons.tipArrowRight,
    NarwhalIcons.tipCircleLeft,
    NarwhalIcons.tipCircleRight,
    NarwhalIcons.tipDiamondLeft,
    NarwhalIcons.tipDiamondRight,
    NarwhalIcons.tipSolidArrowLeft,
    NarwhalIcons.tipSolidArrowRight,
    NarwhalIcons.artifact,
    NarwhalIcons.trapezoid,
    NarwhalIcons.tree,
    NarwhalIcons.triangleLeft,
    NarwhalIcons.triangleRight,
    NarwhalIcons.underline,
    NarwhalIcons.undo,
    NarwhalIcons.upload,
    NarwhalIcons.whiteboard,
    NarwhalIcons.crown,
    NarwhalIcons.party,
    NarwhalIcons.narwhalLogo,
    NarwhalIcons.dashboard,
    NarwhalIcons.projectManagement,
    NarwhalIcons.userExperience,
    NarwhalIcons.note,
    NarwhalIcons.engineering,
    NarwhalIcons.ai,
    NarwhalIcons.arrowLeftCollapse,
    NarwhalIcons.arrowRightExpand,
    NarwhalIcons.figmaDefault,
    NarwhalIcons.figmaColored,
    NarwhalIcons.paste,
    NarwhalIcons.component,
    NarwhalIcons.frame,
    NarwhalIcons.componentInstance,
    NarwhalIcons.jiraCheckbox,
    NarwhalIcons.jiraBug,
    NarwhalIcons.jiraSmall,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 400,
        maxHeight: 400,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: allIcons.map((icon) {
            return NarwhalIconButton(
              icon: icon,
              onPressed: () => onIconSelected(icon),
              isSelected: icon.path == selectedIcon.path,
              iconSafeMode: true,
            );
          }).toList(),
        ),
      ),
    );
  }
}
