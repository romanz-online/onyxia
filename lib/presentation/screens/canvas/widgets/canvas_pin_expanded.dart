import 'package:onyxia/export.dart';
import '../providers/providers.dart';
import 'canvas_comment_pin_expanded.dart';

class CanvasPinExpanded extends ConsumerStatefulWidget {
  final Pin pin;
  final CanvasObject? canvasObject;
  final Offset pinPosition;
  final TransformationController transformationController;
  final Function onRemovePin;

  const CanvasPinExpanded({
    super.key,
    required this.pin,
    this.canvasObject,
    required this.pinPosition,
    required this.transformationController,
    required this.onRemovePin,
  });

  @override
  ConsumerState<CanvasPinExpanded> createState() =>
      _CanvasPinExpandedWidgetState();
}

class _CanvasPinExpandedWidgetState extends ConsumerState<CanvasPinExpanded>
    with TickerProviderStateMixin {
  static const Size _defaultSize = Size(420, 300);

  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;
  HorizontalAnchor _currentAnchor = HorizontalAnchor.rightBottomLeft;

  bool _isEditing = false;
  bool _saving = false;
  TextEditingController? _titleController;
  TextEditingController? _contentController;

  bool _isPinActionMenuOpen = false;
  final GlobalKey _moreButtonKey = GlobalKey();

  /// Calculate optimal anchor position based on viewport bounds
  HorizontalAnchor _calculateOptimalAnchor(
    Offset pinPosition,
    Size size,
    double scale,
  ) {
    // Get actual screen viewport bounds
    final screenSize = MediaQuery.of(context).size;
    final screenViewport =
        Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);

    // Test in preference order: right-side first, then left-side
    final anchors = [
      HorizontalAnchor
          .rightBottomLeft, // Default: right side, pin at bottom-left
      HorizontalAnchor.rightTopLeft, // Right side, pin at top-left
      HorizontalAnchor.leftBottomRight, // Left side, pin at bottom-right
      HorizontalAnchor.leftTopRight, // Left side, pin at top-right
    ];

    for (final anchor in anchors) {
      final expandedRect =
          _calculateExpandedRect(pinPosition, size, anchor, scale);

      // Convert canvas coordinates to screen coordinates
      final transform = widget.transformationController.value;
      final screenTopLeft =
          MatrixUtils.transformPoint(transform, expandedRect.topLeft);
      final screenBottomRight =
          MatrixUtils.transformPoint(transform, expandedRect.bottomRight);
      final screenRect = Rect.fromPoints(screenTopLeft, screenBottomRight);

      // Check if widget fits in actual screen viewport
      if (screenViewport.contains(screenRect.topLeft) &&
          screenViewport.contains(screenRect.bottomRight)) {
        return anchor;
      }
    }

    return HorizontalAnchor.rightBottomLeft; // Fallback
  }

  /// Calculate expanded widget rect for given anchor position
  Rect _calculateExpandedRect(
    Offset pinPosition,
    Size expandedSize,
    HorizontalAnchor anchor,
    double scale,
  ) {
    final double spacing = 8.0 / scale;
    final double pinSize = 36.0 / scale;
    final Size scaledSize = Size(
      expandedSize.width / scale,
      expandedSize.height / scale,
    );

    return switch (anchor) {
      // Expanded to right, pin at its bottom-left corner
      HorizontalAnchor.rightBottomLeft => Rect.fromLTWH(
          pinPosition.dx + pinSize + spacing,
          pinPosition.dy - scaledSize.height + pinSize, // Pin at bottom-left
          scaledSize.width,
          scaledSize.height,
        ),
      // Expanded to right, pin at its top-left corner
      HorizontalAnchor.rightTopLeft => Rect.fromLTWH(
          pinPosition.dx + pinSize + spacing,
          pinPosition.dy, // Pin at top-left
          scaledSize.width,
          scaledSize.height,
        ),
      // Expanded to left, pin at its bottom-right corner
      HorizontalAnchor.leftBottomRight => Rect.fromLTWH(
          pinPosition.dx - scaledSize.width - spacing,
          pinPosition.dy - scaledSize.height + pinSize, // Pin at bottom-right
          scaledSize.width,
          scaledSize.height,
        ),
      // Expanded to left, pin at its top-right corner
      HorizontalAnchor.leftTopRight => Rect.fromLTWH(
          pinPosition.dx - scaledSize.width - spacing,
          pinPosition.dy, // Pin at top-right
          scaledSize.width,
          scaledSize.height,
        ),
    };
  }

  void _closePin() {
    _exitEditMode();
    ref.read(expandedPinProvider.notifier).collapsePin();
  }

  void _navigateToArtifact(Artifact item) {
    context.go(item.navigationUrl(
      ref.read(projectsProvider).selectedProject?.id,
    ));
  }

  void _togglePinActionMenu({required bool isOpen}) {
    setState(() {
      _isPinActionMenuOpen = isOpen;
    });
  }

  void _enterEditMode(Artifact item) {
    if (item is! Note) return;

    setState(() {
      _isEditing = true;
      _titleController = TextEditingController(text: item.name);
      _contentController = TextEditingController(text: item.content);
    });
  }

  void _exitEditMode({bool save = false}) {
    // Unregister focus node from expanded pin provider
    ref.read(expandedPinProvider.notifier).removeFocusNode();

    setState(() {
      _isEditing = false;
      _titleController?.dispose();
      _contentController?.dispose();
      _titleController = null;
      _contentController = null;
    });

    if (_isNewPin && !save) {
      // this is a new pin that was never saved - remove the pin entirely
      widget.onRemovePin();
    }
  }

  void _saveChanges(Artifact item) {
    if (_titleController == null || _contentController == null) {
      return;
    }

    if (item is! Note) return;

    final newTitle = _titleController!.text;
    final newContent = _contentController!.text;

    if (_isNewPin) {
      final newArtifact = Note(name: newTitle, content: newContent);
      ref.read(pinsProvider.notifier).updatePin(
            ref,
            widget.pin.copyWith(linkedArtifactId: newArtifact.id),
          );
      ref.read(artifactsProvider.notifier).addItem(newArtifact);

      // Set flag to prevent auto re-entry into edit mode
      _saving = true;
    } else {
      ref.read(artifactsProvider.notifier).updateItem(
            item.copyWith(name: newTitle, content: newContent),
          );
    }

    _exitEditMode(save: true);
  }

  bool get _isNewPin => widget.pin.linkedArtifactId.isEmpty;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _titleController?.dispose();
    _contentController?.dispose();
    super.dispose();
  }

  Widget _buildPinActionOverlay(VoidCallback closeOverlay, Artifact item) {
    final RenderBox? renderBox =
        _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final position = renderBox.localToGlobal(Offset.zero);
    const minDropdownWidth = 180.0;

    // Calculate left-aligned and right-aligned positions
    final leftAlignedPosition = position.dx;
    final rightAlignedPosition =
        position.dx - minDropdownWidth + renderBox.size.width;

    // Get viewport width to check for overflow
    final viewportWidth = MediaQuery.of(context).size.width;
    final wouldOverflowRight =
        leftAlignedPosition + minDropdownWidth > viewportWidth;

    // Use left-aligned by default, right-aligned if it would overflow
    final finalLeft =
        wouldOverflowRight ? rightAlignedPosition : leftAlignedPosition;

    return Positioned(
      left: finalLeft,
      top: position.dy + renderBox.size.height + 4,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: minDropdownWidth,
          decoration: BoxDecoration(
            color: ThemeHelper.neutral100(context),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: ThemeHelper.neutral400(context),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionMenuItem(
                title: 'View',
                onTap: () {
                  closeOverlay();
                  _navigateToArtifact(item);
                },
              ),
              _buildMenuDivider(context),
              _buildActionMenuItem(
                title: 'Delete Pin',
                onTap: () {
                  closeOverlay();
                  widget.onRemovePin();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuDivider(BuildContext context) => Divider(
        height: 1,
        thickness: 0,
        color: ThemeHelper.neutral400(context),
      );

  Widget _buildActionMenuItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return Container(
          color: isHovered
              ? ThemeHelper.blue400(context).withValues(alpha: 0.5)
              : Colors.transparent,
          child: ListTile(
            title: Text(
              title,
              style: NarwhalStyles.dropdownListTextStyle(context),
            ),
            onTap: onTap,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
          ),
        );
      },
    );
  }

  Alignment _anchorToAlignment(HorizontalAnchor anchor) {
    return switch (anchor) {
      HorizontalAnchor.rightBottomLeft => Alignment.bottomLeft,
      HorizontalAnchor.rightTopLeft => Alignment.topLeft,
      HorizontalAnchor.leftBottomRight => Alignment.bottomRight,
      HorizontalAnchor.leftTopRight => Alignment.topRight,
    };
  }

  @override
  Widget build(BuildContext context) {
    try {
      final double scale =
          widget.transformationController.value.getMaxScaleOnAxis();

      final artifact = ref.watch(artifactsProvider).firstWhere(
            (req) => req.id == widget.pin.linkedArtifactId,
            orElse: () => Note(),
          );

      // Auto-enter edit mode for new pins (but not right after saving)
      if (!_isEditing && _isNewPin && !_saving) {
        _enterEditMode(artifact);
      }

      // Reset the flag when pin is no longer new (update propagated)
      if (!_isNewPin && _saving) {
        setState(() {
          _saving = false;
        });
      }

      // Calculate positioning
      final HorizontalAnchor optimalAnchor = _calculateOptimalAnchor(
        widget.pinPosition,
        _defaultSize,
        scale,
      );
      _currentAnchor = optimalAnchor;
      final Rect expandedRect = _calculateExpandedRect(
        widget.pinPosition,
        _defaultSize,
        optimalAnchor,
        scale,
      );

      final Color borderColor = ThemeHelper.blue500(context);

      return Positioned(
        left: expandedRect.left,
        top: expandedRect.top - 24,
        width: _defaultSize.width,
        height: _defaultSize.height,
        child: Transform.scale(
          alignment: Alignment.topLeft,
          scale: 1 / scale,
          child: AnimatedBuilder(
            animation: _entranceAnimation,
            builder: (context, child) => Transform.scale(
              alignment: _anchorToAlignment(_currentAnchor),
              scale: _entranceAnimation.value,
              child: child,
            ),
            child: MouseRegion(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: _defaultSize.width,
                  height: _defaultSize.height,
                  decoration: BoxDecoration(
                    color: ThemeHelper.neutral100(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeHelper.neutral900(context)
                            .withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with icon, title, and action buttons
                      Container(
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: _isEditing ? 8 : 12,
                          bottom: 4,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            NarwhalIconButton(
                              icon: NarwhalIcons.edit,
                              size: 32,
                              iconSafeMode: true,
                              enabled: false,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _isEditing
                                  ? TextField(
                                      controller: _titleController,
                                      autofocus: true,
                                      style: NarwhalTextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Untitled',
                                        hoverColor:
                                            ThemeHelper.neutral100(context),
                                        fillColor:
                                            ThemeHelper.neutral100(context),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color:
                                                ThemeHelper.neutral400(context),
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color:
                                                ThemeHelper.neutral400(context),
                                            width: 1,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                          bottom: 18,
                                          top: 6,
                                        ),
                                        isDense: true,
                                      ),
                                    )
                                  : Padding(
                                      padding: EdgeInsets.only(
                                        left: 8,
                                        top: 4,
                                        bottom: 4,
                                      ),
                                      child: Text(
                                        artifact.name.isEmpty
                                            ? 'Untitled'
                                            : artifact.name,
                                        style: NarwhalTextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              ThemeHelper.neutral900(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                            ),
                            _isEditing
                                ? const SizedBox.shrink()
                                : NarwhalIconButton(
                                    icon: NarwhalIcons.editDefault,
                                    size: 32,
                                    onPressed: () => _enterEditMode(artifact),
                                  ),
                            const SizedBox(width: 6),
                            NarwhalOverlay(
                              isOpen: _isPinActionMenuOpen,
                              onClose: () =>
                                  _togglePinActionMenu(isOpen: false),
                              closingDelay: const Duration(milliseconds: 100),
                              builder: (context, closeOverlay) =>
                                  _buildPinActionOverlay(
                                      closeOverlay, artifact),
                              child: NarwhalIconButton(
                                key: _moreButtonKey,
                                icon: NarwhalIcons.moreDots,
                                size: 32,
                                isPressed: _isPinActionMenuOpen,
                                onPressed: () => _togglePinActionMenu(
                                    isOpen: !_isPinActionMenuOpen),
                              ),
                            ),
                            const SizedBox(width: 6),
                            NarwhalIconButton(
                              icon: NarwhalIcons.close,
                              size: 32,
                              onPressed: _closePin,
                            ),
                          ],
                        ),
                      ),
                      // Content area
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 12,
                          ),
                          child: _isEditing
                              ? Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color:
                                                ThemeHelper.neutral400(context),
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          controller: _contentController!,
                                          maxLines: null,
                                          expands: true,
                                          style: NarwhalTextStyle(
                                            fontSize: 13,
                                            color:
                                                ThemeHelper.neutral900(context),
                                            height: 1.5,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Start typing...',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      spacing: 8,
                                      children: [
                                        NarwhalButton(
                                          text: 'Cancel',
                                          onTap: () =>
                                              _exitEditMode(save: false),
                                          type: NarwhalButtonType.light,
                                        ),
                                        NarwhalButton(
                                          text: 'Save',
                                          onTap: () => _saveChanges(artifact),
                                          type: NarwhalButtonType.light,
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Padding(
                                  padding: EdgeInsets.only(left: 9, top: 13),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      artifact is Note ? artifact.content : '',
                                      style: NarwhalTextStyle(
                                        fontSize: 13,
                                        color: ThemeHelper.neutral900(context),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
