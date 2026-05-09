import 'package:onyxia/export.dart';
import '../providers/providers.dart';

// Custom Intents for comment input keyboard actions
class NewLineIntent extends Intent {
  const NewLineIntent();
}

class SubmitIntent extends Intent {
  const SubmitIntent();
}

class CanvasCommentPinExpanded extends ConsumerStatefulWidget {
  final Comment comment;
  final CanvasObject? canvasObject;
  final Offset position;
  final TransformationController transformationController;
  final VoidCallback? onDeleteComment;

  const CanvasCommentPinExpanded({
    super.key,
    required this.comment,
    this.canvasObject,
    required this.position,
    required this.transformationController,
    this.onDeleteComment,
  });

  @override
  ConsumerState<CanvasCommentPinExpanded> createState() =>
      _CanvasCommentPinExpandedState();
}

enum HorizontalAnchor {
  rightBottomLeft, // Expanded to right, pin at bottom-left corner
  rightTopLeft, // Expanded to right, pin at top-left corner
  leftBottomRight, // Expanded to left, pin at bottom-right corner
  leftTopRight, // Expanded to left, pin at top-right corner
}

class _CanvasCommentPinExpandedState
    extends ConsumerState<CanvasCommentPinExpanded>
    with TickerProviderStateMixin {
  static const double _defaultWidth = 320;
  static const double _minHeight = 150;
  static const double _maxHeight = 500;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;
  HorizontalAnchor _currentAnchor = HorizontalAnchor.rightBottomLeft;

  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  final ScrollController _commentsScrollController = ScrollController();

  bool _isCommentActionMenuOpen = false;
  final GlobalKey _moreButtonKey = GlobalKey();

  String? _openCommentMenuId;
  final Map<String, GlobalKey> _commentMenuKeys = {};

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
    _replyController.dispose();
    _replyFocusNode.dispose();
    _commentsScrollController.dispose();
    super.dispose();
  }

  void _onClose() {
    ref.read(expandedPinProvider.notifier).collapsePin();
  }

  void _onMoreOptions() {
    setState(() {
      _isCommentActionMenuOpen = !_isCommentActionMenuOpen;
    });
  }

  void _toggleCommentActionMenu({required bool isOpen}) {
    setState(() {
      _isCommentActionMenuOpen = isOpen;
    });
  }

  void _deleteThread() {
    _toggleCommentActionMenu(isOpen: false);
    ref.read(expandedPinProvider.notifier).collapsePin();

    try {
      widget.onDeleteComment?.call();
    } catch (e) {
      NarwhalToast.show(
        text: 'Failed to delete comment thread',
        type: ToastType.error,
      );
    }
  }

  void _submitReply() {
    final text = _replyController.text.trim();
    if (text.isNotEmpty) {
      ref
          .read(commentsProvider(ref.read(currentCanvasProvider)?.id ?? '')
              .notifier)
          .addSubComment(widget.comment.id, text);
      _replyController.clear();

      Future.delayed(const Duration(milliseconds: 150), () {
        if (_commentsScrollController.hasClients) {
          final maxExtent = _commentsScrollController.position.maxScrollExtent;

          if (maxExtent > 0) {
            _commentsScrollController.animateTo(
              maxExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );

            Future.delayed(const Duration(milliseconds: 350), () {
              if (_commentsScrollController.hasClients) {
                final newMax =
                    _commentsScrollController.position.maxScrollExtent;
                if (newMax > maxExtent) {
                  debugPrint(
                      '📜 Retry scroll: newMax = ${newMax.toStringAsFixed(1)}');
                  _commentsScrollController.animateTo(
                    newMax,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              }
            });
          } else {
            // Layout not ready, try again
            debugPrint('⏳ Layout not ready, retrying...');
            Future.delayed(const Duration(milliseconds: 200), () {
              if (_commentsScrollController.hasClients) {
                final newMax =
                    _commentsScrollController.position.maxScrollExtent;
                debugPrint(
                    '📜 Retry scroll: newMax = ${newMax.toStringAsFixed(1)}');
                _commentsScrollController.animateTo(
                  newMax,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      });
    }
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
    final double scale =
        widget.transformationController.value.getMaxScaleOnAxis();
    final int commentCount = 1 + widget.comment.subComments.length;
    final double containerHeight = _estimateContentHeight(commentCount);

    final anchor = _calculateOptimalAnchor(
      widget.position,
      Size(_defaultWidth, containerHeight),
      scale,
    );
    _currentAnchor = anchor;

    final rect = _calculateExpandedRect(
      widget.position,
      Size(_defaultWidth, containerHeight),
      anchor,
      scale,
    );

    final bool isUpwardAnchor = anchor == HorizontalAnchor.rightBottomLeft ||
        anchor == HorizontalAnchor.leftBottomRight;
    final double positionedTop = isUpwardAnchor
        ? widget.position.dy + (1.0 / scale)
        : rect.top - (37.0 / scale);

    return Positioned(
      top: positionedTop,
      left: rect.left,
      width: rect.width * scale,
      child: Transform.scale(
        alignment: Alignment.topLeft,
        scale: 1 / scale,
        child: FractionalTranslation(
          translation: isUpwardAnchor ? const Offset(0, -1) : Offset.zero,
          child: AnimatedBuilder(
            animation: _entranceAnimation,
            builder: (context, child) => Transform.scale(
              alignment: _anchorToAlignment(_currentAnchor),
              scale: _entranceAnimation.value,
              child: child,
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.basic,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: _defaultWidth,
                  constraints: BoxConstraints(
                    minHeight: _minHeight,
                    maxHeight: _maxHeight,
                  ),
                  decoration: BoxDecoration(
                    color: ThemeHelper.neutral100(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ThemeHelper.neutral400(context),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      Flexible(
                        fit: FlexFit.loose,
                        child: _buildCommentsList(),
                      ),
                      _buildReplyInput(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Calculate optimal anchor position based on available space
  HorizontalAnchor _calculateOptimalAnchor(
    Offset pinPosition,
    Size size,
    double scale,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final screenViewport = Rect.fromLTWH(
      0,
      0,
      screenSize.width,
      screenSize.height,
    );

    // Test anchors in preference order
    final anchors = [
      HorizontalAnchor.rightBottomLeft, // Default: right side, bottom aligned
      HorizontalAnchor.rightTopLeft, // Right side, top aligned
      HorizontalAnchor.leftBottomRight, // Left side, bottom aligned
      HorizontalAnchor.leftTopRight, // Left side, top aligned
    ];

    for (final anchor in anchors) {
      final rect = _calculateExpandedRect(pinPosition, size, anchor, scale);
      final screenRect = _transformRectToScreen(rect);

      if (screenViewport.contains(screenRect.topLeft) &&
          screenViewport.contains(screenRect.bottomRight)) {
        return anchor;
      }
    }

    // Fallback to default
    return HorizontalAnchor.rightBottomLeft;
  }

  /// Calculate expanded widget rect for given anchor position
  Rect _calculateExpandedRect(
    Offset pinPosition,
    Size expandedSize,
    HorizontalAnchor anchor,
    double scale,
  ) {
    const double spacing = 8.0;
    const double pinSize = 36.0;

    final Size scaledSize = Size(
      expandedSize.width / scale,
      expandedSize.height / scale,
    );
    final double scaledSpacing = spacing / scale;
    final double scaledPinSize = pinSize / scale;

    return switch (anchor) {
      HorizontalAnchor.rightBottomLeft => Rect.fromLTWH(
          pinPosition.dx + scaledPinSize + scaledSpacing,
          pinPosition.dy - scaledSize.height + scaledPinSize,
          scaledSize.width,
          scaledSize.height,
        ),
      HorizontalAnchor.rightTopLeft => Rect.fromLTWH(
          pinPosition.dx + scaledPinSize + scaledSpacing,
          pinPosition.dy,
          scaledSize.width,
          scaledSize.height,
        ),
      HorizontalAnchor.leftBottomRight => Rect.fromLTWH(
          pinPosition.dx - scaledSize.width - scaledSpacing,
          pinPosition.dy - scaledSize.height + scaledPinSize,
          scaledSize.width,
          scaledSize.height,
        ),
      HorizontalAnchor.leftTopRight => Rect.fromLTWH(
          pinPosition.dx - scaledSize.width - scaledSpacing,
          pinPosition.dy,
          scaledSize.width,
          scaledSize.height,
        ),
    };
  }

  /// Transform canvas rect to screen coordinates
  Rect _transformRectToScreen(Rect canvasRect) {
    final transform = widget.transformationController.value;
    final topLeft = MatrixUtils.transformPoint(transform, canvasRect.topLeft);
    final bottomRight =
        MatrixUtils.transformPoint(transform, canvasRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  double _estimateContentHeight(int commentCount) {
    const double headerHeight = 50;
    const double replyInputHeight = 50;
    const double commentHeight = 60;
    const double padding = 24;

    final double contentHeight = headerHeight +
        replyInputHeight +
        (commentCount * commentHeight) +
        padding;

    final clampedHeight = contentHeight.clamp(_minHeight, _maxHeight);

    return clampedHeight;
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Comment',
                  style: NarwhalTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.neutral900(context),
                  ),
                ),
              ),
              NarwhalOverlay(
                isOpen: _isCommentActionMenuOpen,
                onClose: () => _toggleCommentActionMenu(isOpen: false),
                closingDelay: const Duration(milliseconds: 100),
                builder: (context, closeOverlay) =>
                    _buildCommentActionOverlay(closeOverlay),
                child: NarwhalIconButton(
                  key: _moreButtonKey,
                  icon: NarwhalIcons.moreDots,
                  size: 30,
                  isPressed: _isCommentActionMenuOpen,
                  onPressed: _onMoreOptions,
                ),
              ),
              const SizedBox(width: 6),
              NarwhalIconButton(
                icon: NarwhalIcons.close,
                size: 30,
                onPressed: _onClose,
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          color: ThemeHelper.neutral400(context),
        ),
      ],
    );
  }

  Widget _buildCommentsList() {
    return SingleChildScrollView(
      controller: _commentsScrollController, // ✅ ADD: Attach controller
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildComment(
              commentId: widget.comment.id,
              authorId: widget.comment.authorId,
              text: widget.comment.text,
              createdAt: widget.comment.createdAt,
              isSubComment: false,
            ),
            ...widget.comment.subComments.map(
              (subComment) => _buildComment(
                commentId: subComment.id,
                authorId: subComment.authorId,
                text: subComment.text,
                createdAt: subComment.createdAt,
                isSubComment: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment({
    required String commentId,
    required String authorId,
    required String text,
    required DateTime? createdAt,
    required bool isSubComment,
  }) {
    return FutureBuilder<UserDefinition>(
      future: ref.read(userLookupProvider).getUserById(authorId),
      builder: (context, snapshot) {
        final user = snapshot.data ?? UserDefinition.initial();
        final timeAgo = createdAt != null
            ? TimestampService.formatTimeAgo(
                createdAt,
                daysOnly: true,
              )
            : '';

        return Container(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name.isNotEmpty ? user.name : 'Unknown User',
                          style: NarwhalTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ThemeHelper.neutral900(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (timeAgo.isNotEmpty)
                          Text(
                            timeAgo,
                            style: NarwhalTextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: ThemeHelper.neutral900(context)
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              NarwhalOverlay(
                isOpen: _openCommentMenuId == commentId,
                onClose: () => setState(() => _openCommentMenuId = null),
                closingDelay: const Duration(milliseconds: 100),
                builder: (context, closeOverlay) => _buildCommentMenuOverlay(
                  commentId,
                  authorId,
                  isSubComment,
                  _commentMenuKeys[commentId]!,
                  closeOverlay,
                ),
                child: NarwhalIconButton(
                  key: _commentMenuKeys.putIfAbsent(
                      commentId, () => GlobalKey()),
                  icon: NarwhalIcons.moreDots,
                  size: 28,
                  enabled: _isCurrentUserAuthor(authorId),
                  isPressed: _openCommentMenuId == commentId,
                  onPressed: () => setState(() => _openCommentMenuId =
                      _openCommentMenuId == commentId ? null : commentId),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter):
                  const NewLineIntent(),
              LogicalKeySet(LogicalKeyboardKey.enter): const SubmitIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                NewLineIntent:
                    CallbackAction<NewLineIntent>(onInvoke: (intent) {
                  // Insert newline manually at cursor position
                  final selection = _replyController.selection;
                  _replyController.value = _replyController.value.copyWith(
                    text: _replyController.text
                        .replaceRange(selection.start, selection.end, '\n'),
                    selection:
                        TextSelection.collapsed(offset: selection.start + 1),
                  );
                  return null;
                }),
                SubmitIntent: CallbackAction<SubmitIntent>(onInvoke: (intent) {
                  _submitReply();
                  return null;
                }),
              },
              child: TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Enter Reply',
                  hintStyle: NarwhalTextStyle(
                    color: ThemeHelper.neutral500(context),
                    fontSize: 15,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: ThemeHelper.neutral400(context),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: ThemeHelper.neutral500(context),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: ThemeHelper.neutral400(context),
                      width: 1,
                    ),
                  ),
                  fillColor: ThemeHelper.neutral100(context),
                  filled: true,
                  hoverColor: ThemeHelper.neutral100(context),
                  isDense: true,
                  contentPadding: const EdgeInsets.only(
                    left: 10,
                    right: 38,
                    top: 12,
                    bottom: 12,
                  ),
                ),
                maxLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ),
          ),
          // Button positioned inside TextField boundaries
          Positioned(
            right: 5,
            bottom: 4,
            child: NarwhalIconButton(
              icon: NarwhalIcons.enter,
              onPressed: _submitReply,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentActionOverlay(VoidCallback closeOverlay) {
    final RenderBox? renderBox =
        _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final position = renderBox.localToGlobal(Offset.zero);
    const minDropdownWidth = 140.0;

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
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionMenuItem(
                title: 'Delete',
                onTap: () {
                  closeOverlay();
                  _deleteThread();
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
    final canvasStyle = NarwhalStyles.dropdownListTextStyle(context)
        .copyWith(color: ThemeHelper.neutral900(context));
    return HoverBuilder(
      builder: (context, isHovered) {
        return Container(
          color: isHovered
              ? ThemeHelper.blue400(context).withValues(alpha: 0.5)
              : Colors.transparent,
          child: ListTile(
            title: Text(
              title,
              style: canvasStyle,
            ),
            onTap: onTap,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        );
      },
    );
  }

  Widget _buildCommentMenuOverlay(
    String commentId,
    String authorId,
    bool isSubComment,
    GlobalKey buttonKey,
    VoidCallback closeOverlay,
  ) {
    final RenderBox? renderBox =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final position = renderBox.localToGlobal(Offset.zero);
    const minDropdownWidth = 120.0;

    // Calculate left-aligned and right-aligned positions
    final leftAlignedPosition = position.dx;
    final rightAlignedPosition =
        position.dx - minDropdownWidth + renderBox.size.width;

    // Check for left-side overflow to determine if we need to fall back to left-alignment
    final wouldOverflowLeft = rightAlignedPosition < 0;

    // Use right-aligned by default, left-aligned if it would overflow off the left side
    final finalLeft =
        wouldOverflowLeft ? leftAlignedPosition : rightAlignedPosition;

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
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionMenuItem(
                title: 'Edit',
                onTap: () {
                  closeOverlay();
                  _editComment(commentId);
                },
              ),
              _buildMenuDivider(context),
              _buildActionMenuItem(
                title: 'Remove',
                onTap: () {
                  closeOverlay();
                  _removeComment(commentId, isSubComment);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editComment(String commentId) {
    NarwhalToast.show(
      text: 'Edit - Unimplemented',
      type: ToastType.info,
    );
  }

  bool _isCurrentUserAuthor(String authorId) {
    final currentUser = ref.read(currentUserProvider);
    return currentUser.id == authorId;
  }

  void _removeComment(String commentId, bool isSubComment) {
    setState(() => _openCommentMenuId = null);

    if (isSubComment) {
      ref
          .read(commentsProvider(ref.read(currentCanvasProvider)?.id ?? '')
              .notifier)
          .deleteSubComment(widget.comment.id, commentId);
    } else {
      ref
          .read(commentsProvider(ref.read(currentCanvasProvider)?.id ?? '')
              .notifier)
          .deleteComment(commentId: commentId);
      NarwhalToast.show(
        text: 'Comment removed',
        type: ToastType.info,
      );
    }
  }
}
