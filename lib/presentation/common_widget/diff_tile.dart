import 'package:onyxia/export.dart';
import 'package:intl/intl.dart';

class DiffTile extends ConsumerStatefulWidget {
  final HistoryDiff diff;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final Function(String) onRename;
  final User user;
  final bool isPseudoMilestone;
  final bool hasChildDiffs;
  final bool isExpanded;
  final VoidCallback? onCaretTap;
  final bool isChildDiff;

  const DiffTile({
    super.key,
    required this.diff,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
    required this.onRestore,
    required this.onRename,
    required this.user,
    this.isPseudoMilestone = false,
    this.hasChildDiffs = false,
    this.isExpanded = false,
    this.onCaretTap,
    this.isChildDiff = false,
  });

  @override
  ConsumerState<DiffTile> createState() => _DiffTileState();
}

class _DiffTileState extends ConsumerState<DiffTile> {
  bool isEditing = false;
  bool _isMenuOpen = false;
  TextEditingController? editingController;
  final GlobalKey _menuButtonKey = GlobalKey();

  @override
  void dispose() {
    editingController?.dispose();
    super.dispose();
  }

  void startEditingVersionNumber() {
    setState(() {
      isEditing = true;
      editingController = TextEditingController(text: widget.diff.title);
    });
    // Focus the text field and select all text after the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      editingController?.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.diff.title.length,
      );
    });
  }

  void cancelEditing() {
    setState(() {
      isEditing = false;
      editingController?.dispose();
      editingController = null;
    });
  }

  void renameDiff() {
    widget.onRename(editingController?.text.trim() ?? '');
    cancelEditing();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _closeMenu() {
    setState(() {
      _isMenuOpen = false;
    });
  }

  void _handleMenuAction(String action) {
    debugPrint('DiffTile: _handleMenuAction called with action: $action');
    switch (action) {
      case 'restore':
        debugPrint('DiffTile: Calling widget.onRestore()');
        widget.onRestore();
        break;
      case 'rename':
        startEditingVersionNumber();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isSelected
        ? ThemeHelper.blue400(context).withValues(alpha: 0.5)
        : Colors.transparent;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: backgroundColor,
      child: ListTile(
        onTap: widget.onTap,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                // Indent icon for non-milestone diffs
                if (widget.isChildDiff)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: NarwhalIcon(
                      NarwhalIcons.indent,
                      size: 24,
                      color: ThemeHelper.neutral500(context),
                    ),
                  ),
                // Caret button for expandable milestone groups
                if (widget.hasChildDiffs)
                  InkWell(
                    onTap: widget.onCaretTap,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: NarwhalIcon(
                        widget.isExpanded
                            ? NarwhalIcons.expandArrowExpanded
                            : NarwhalIcons.expandArrowCollapsed,
                        size: 16,
                        color: ThemeHelper.neutral600(context),
                      ),
                    ),
                  ),
                if (widget.hasChildDiffs) const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title
                      isEditing
                          ? ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 200,
                              ),
                              child: TextField(
                                controller: editingController,
                                autofocus: true,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: ThemeHelper.neutral800(context),
                                    ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  isDense: true,
                                ),
                                onSubmitted: (value) => renameDiff(),
                                onTapOutside: (event) => cancelEditing(),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.diff.title.isEmpty
                                        ? DateFormat('MMM d, h:mm a')
                                            .format(widget.diff.timestamp)
                                        : widget.diff.title,
                                    style: NarwhalTextStyle(
                                      fontSize: 14,
                                      color: ThemeHelper.neutral800(context),
                                      fontWeight: FontWeight.w600,
                                      fontFamily: "Segoe UI",
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (widget.diff.title.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    DateFormat('MMM d, h:mm a')
                                        .format(widget.diff.timestamp),
                                    style: NarwhalTextStyle(
                                      fontSize: 12,
                                      color: ThemeHelper.neutral500(context),
                                      fontWeight: FontWeight.w400,
                                      fontFamily: "Segoe UI",
                                    ),
                                  ),
                                ],
                              ],
                            ),
                      // Current chip
                      if (widget.isCurrent) ...[
                        SizedBox(height: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeHelper.blue700(context)
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Current Version',
                            style: NarwhalTextStyle(
                              fontSize: 12,
                              color: ThemeHelper.neutral100(context),
                              fontWeight: FontWeight.w700,
                              fontFamily: "Segoe UI",
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // More button (if selected)
                if (widget.isSelected)
                  NarwhalOverlay(
                    isOpen: _isMenuOpen,
                    onClose: _closeMenu,
                    closingDelay: const Duration(milliseconds: 100),
                    builder: (context, closeOverlay) {
                      final RenderBox? buttonRenderBox =
                          _menuButtonKey.currentContext?.findRenderObject()
                              as RenderBox?;
                      final buttonSize = buttonRenderBox?.size ?? Size.zero;
                      final buttonOffset =
                          buttonRenderBox?.localToGlobal(Offset.zero) ??
                              Offset.zero;

                      return _DiffTileMenuOverlay(
                        isCurrent: widget.isCurrent,
                        offset: buttonOffset,
                        buttonSize: buttonSize,
                        onClose: closeOverlay,
                        onAction: (action) {
                          closeOverlay();
                          _handleMenuAction(action);
                        },
                      );
                    },
                    child: HoverBuilder(builder: (context, isMenuHovered) {
                      return InkWell(
                        key: _menuButtonKey,
                        onTap: _toggleMenu,
                        borderRadius: BorderRadius.circular(4),
                        splashColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        child: NarwhalIcon(
                          NarwhalIcons.moreDots,
                          size: 20,
                          color: isMenuHovered
                              ? ThemeHelper.neutral500(context)
                              : ThemeHelper.neutral800(context),
                        ),
                      );
                    }),
                  ),
              ],
            );
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            if (widget.user.name.isNotEmpty)
              Row(
                children: [
                  if (widget.isChildDiff) SizedBox(width: 32),
                  Text(
                    widget.user.name,
                    style: NarwhalTextStyle(
                      fontSize: 12,
                      color: ThemeHelper.neutral800(context),
                      fontWeight: FontWeight.w600,
                      fontFamily: "Segoe UI",
                    ),
                  ),
                ],
              ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DiffTileMenuOverlay extends ConsumerWidget {
  final bool isCurrent;
  final Offset offset;
  final Size buttonSize;
  final VoidCallback onClose;
  final Function(String) onAction;

  const _DiffTileMenuOverlay({
    required this.isCurrent,
    required this.offset,
    required this.buttonSize,
    required this.onClose,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: offset.dy + buttonSize.height,
      left: offset.dx + buttonSize.width - 170,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: ThemeHelper.neutral100(context),
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ThemeHelper.neutral400(context),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(
                context,
                title: 'Restore This Version',
                onTap: () {
                  debugPrint('DiffTile: Restore This Version clicked');
                  onAction('restore');
                },
                isActive: !isCurrent,
              ),
              _buildDivider(context),
              _buildMenuItem(
                context,
                title: 'Name This Version',
                onTap: () => onAction('rename'),
                isActive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: isActive ? onTap : () {},
      mouseCursor:
          isActive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isActive
                          ? ThemeHelper.neutral900(context)
                          : ThemeHelper.neutral600(context),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) => Divider(
        height: 1,
        thickness: 1.5,
        color: ThemeHelper.neutral400(context),
      );
}
