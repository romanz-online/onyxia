import 'package:onyxia/export.dart';
import 'dart:math' as math;
import '../providers/providers.dart';

// Custom Intents for comment input keyboard actions
class NewLineIntent extends Intent {
  const NewLineIntent();
}

class SubmitIntent extends Intent {
  const SubmitIntent();
}

class CanvasCommentPin extends ConsumerStatefulWidget {
  final Comment comment;
  final CanvasObject? canvasObject;
  final Offset? position;
  final TransformationController transformationController;
  final bool isExpanded;
  final VoidCallback onTap;

  const CanvasCommentPin({
    super.key,
    required this.comment,
    this.canvasObject,
    required this.transformationController,
    this.position,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  ConsumerState<CanvasCommentPin> createState() => _CanvasCommentPinState();
}

class _CanvasCommentPinState extends ConsumerState<CanvasCommentPin>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _paddingAnimation;
  late Animation<double> _shadowAnimation;
  String? _lastCommentText;
  final TextEditingController _commentController = TextEditingController();
  final GlobalKey _inputContainerKey = GlobalKey();
  double _currentInputHeight = 45.0; // Start with minimum height

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _initializeAnimations();

    // Listen to text changes to update input height
    _commentController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateInputHeight();
      });
    });
  }

  double _calculateInputHeight() {
    final RenderBox? renderBox =
        _inputContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      return renderBox.size.height;
    }
    return _currentInputHeight; // Fallback to current height if not yet rendered
  }

  void _updateInputHeight() {
    final newHeight = _calculateInputHeight();
    if (newHeight != _currentInputHeight) {
      setState(() {
        _currentInputHeight = newHeight;
      });
    }
  }

  void _initializeAnimations() {
    _widthAnimation = Tween<double>(
      begin: 36.0,
      end: 276.0, // Fixed width for comment pins
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    ));

    _heightAnimation = Tween<double>(
      begin: 36.0,
      end: 70.0, // Will be updated dynamically
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));

    _paddingAnimation = Tween<double>(
      begin: 3.5,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    ));

    _shadowAnimation = Tween<double>(
      begin: 1.0,
      end: 3.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  bool get isExpanded => widget.isExpanded;

  bool get isTemporaryComment =>
      ref.read(commentsProvider).temporaryComment?.id == widget.comment.id;

  Offset get _position {
    if (widget.position != null) {
      return widget.position!;
    }
    // Use the comment's position if available, otherwise return a default position
    return widget.comment.getOffset(parent: widget.canvasObject);
  }

  double _calculateRequiredHeight(BuildContext context) {
    // Available width for expanded pin text:
    // Expanded pin width: 276px (from _widthAnimation.end)
    // Avatar: 27px + avatar padding (8px on left/right = 16px total)
    // Text content padding: left 4px + right 12px = 16px
    final double availableTextWidth =
        276.0 - 27.0 - 16.0 - 4.0 - 12.0; // = 217px

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: widget.comment.text,
        style: NarwhalTextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ThemeHelper.neutral900(context),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: availableTextWidth);

    final double textHeight = textPainter.height;
    final double avatarAndPaddingHeight =
        27.0 + 16.0; // avatar size + avatar padding (8px top/bottom)
    final double headerHeight =
        20.0; // height for author name and timestamp row
    final double textPadding = 8.0 * 2; // text area top + bottom padding
    final double minHeight = 60.0; // minimum expanded height
    final double textHeightBuffer =
        textHeight > 20 ? textHeight * 0.2 : 0; // 10% buffer for multi-line
    final double calculatedHeight = headerHeight +
        4.0 + // spacing between header and text (SizedBox(height: 4))
        textHeight +
        textPadding +
        // 8.0 + // additional buffer for text rendering differences
        textHeightBuffer; // multi-line buffer

    return math.max(
      minHeight,
      math.max(avatarAndPaddingHeight, calculatedHeight),
    );
  }

  void _updateHeightAnimation(String text, BuildContext context) {
    _heightAnimation = Tween<double>(
      begin: 36.0,
      end: _calculateRequiredHeight(context),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    ));
  }

  void _handleHoverEnter() {
    if (!isExpanded && !isTemporaryComment) {
      _animationController.forward();
    }
  }

  void _handleHoverExit() {
    if (!isExpanded && !isTemporaryComment) {
      _animationController.reverse();
    }
  }

  void _onTap() {
    if (isExpanded) {
      widget.onTap();
      _handleHoverExit();
    } else {
      _animationController
          .reset(); // Instantly reset to collapsed state without animation
      widget.onTap();
    }
  }

  void _saveComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      ref.read(commentsProvider.notifier).saveTemporaryComment(text);
      _commentController.clear();
    } else {
      ref.read(commentsProvider.notifier).clearTemporaryComment();
      _commentController.clear();
    }
  }

  Widget _buildEditableCommentInput() {
    final double scale =
        widget.transformationController.value.getMaxScaleOnAxis();
    final containerWidth = 360.0;

    // Update height after widget is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateInputHeight());

    return Positioned(
      top: _position.dy - (_currentInputHeight / scale),
      left: _position.dx,
      child: Transform.scale(
        alignment: Alignment.topLeft,
        scale: 1 / scale,
        child: FutureBuilder<User>(
          future: ref
              .read(userLookupProvider)
              .getUserById(widget.comment.createdBy),
          builder: (context, snapshot) {
            return Container(
              key: _inputContainerKey,
              width: containerWidth,
              decoration: BoxDecoration(
                color: ThemeHelper.neutral100(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(0),
                ),
                border: Border.all(
                  color: ThemeHelper.blue500(context),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 41),
                    child: Shortcuts(
                      shortcuts: <LogicalKeySet, Intent>{
                        LogicalKeySet(LogicalKeyboardKey.shift,
                            LogicalKeyboardKey.enter): const NewLineIntent(),
                        LogicalKeySet(LogicalKeyboardKey.enter):
                            const SubmitIntent(),
                      },
                      child: Actions(
                        actions: <Type, Action<Intent>>{
                          NewLineIntent:
                              CallbackAction<NewLineIntent>(onInvoke: (intent) {
                            // Insert newline manually at cursor position
                            final selection = _commentController.selection;
                            _commentController.value =
                                _commentController.value.copyWith(
                              text: _commentController.text.replaceRange(
                                  selection.start, selection.end, '\n'),
                              selection: TextSelection.collapsed(
                                  offset: selection.start + 1),
                            );
                            return null;
                          }),
                          SubmitIntent:
                              CallbackAction<SubmitIntent>(onInvoke: (intent) {
                            _saveComment();
                            return null;
                          }),
                        },
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add Comment',
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
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                        ),
                      ),
                    ),
                  ),
                  // Button positioned inside TextField boundaries
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: NarwhalIconButton(
                      icon: NarwhalIcons.enter,
                      onPressed: _saveComment,
                      size: 30,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Show editable input for temporary comments
      if (isTemporaryComment) return _buildEditableCommentInput();

      // Regular pin display logic
      final double scale =
          widget.transformationController.value.getMaxScaleOnAxis();

      if (_lastCommentText != widget.comment.text) {
        _lastCommentText = widget.comment.text;
        // Use WidgetsBinding to update animation after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateHeightAnimation(widget.comment.text, context);
        });
      }

      final bool isSelected = isExpanded;
      final Color backgroundColor = ThemeHelper.neutral100(context);
      final Color outerBorderColor = ThemeHelper.neutral400(context);
      final Color selectionColor = ThemeHelper.blue500(context);

      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Position container so pin's bottom-left stays at _position (accounting for zoom)
          final containerTop = _position.dy - (_heightAnimation.value / scale);
          final widgetWidth = _widthAnimation.value / scale;
          final widgetHeight = _heightAnimation.value / scale;

          return Positioned(
            top: containerTop,
            left: _position.dx,
            width: widgetWidth * scale,
            height: widgetHeight * scale,
            child: Transform.scale(
              alignment: Alignment.topLeft,
              scale: 1 / scale,
              child: MouseRegion(
                onEnter: (_) => _handleHoverEnter(),
                onExit: (_) => _handleHoverExit(),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _onTap,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: _widthAnimation.value,
                        height: _heightAnimation.value,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                isSelected ? selectionColor : outerBorderColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                            bottomLeft: Radius.circular(1),
                          ),
                          color: backgroundColor,
                          boxShadow: [
                            BoxShadow(
                              color: outerBorderColor.withValues(alpha: 0.8),
                              blurRadius: _shadowAnimation.value,
                            ),
                          ],
                        ),
                        child: FutureBuilder<User>(
                          future: ref
                              .read(userLookupProvider)
                              .getUserById(widget.comment.createdBy),
                          builder: (context, snapshot) {
                            final user = snapshot.data ?? User.initial();
                            final timeAgo = widget.comment.createdAt != null
                                ? TimestampService.formatTimeAgo(
                                    widget.comment.createdAt!,
                                    daysOnly: true,
                                  )
                                : '';

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar (always visible, position unchanged)
                                Padding(
                                  padding: EdgeInsets.all(isSelected
                                      ? 3.0
                                      : _paddingAnimation.value),
                                  child: GestureDetector(
                                    onTap: _onTap,
                                    child: InitialsCircle(
                                      name: user.name,
                                      size: 27,
                                    ),
                                  ),
                                ),
                                // Content column (username/timestamp + text)
                                if (_animationController.value > 0.1)
                                  Expanded(
                                    child: Opacity(
                                      opacity: _opacityAnimation.value,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                          left: 4,
                                          top: 8,
                                          bottom: 8,
                                        ),
                                        child: SizedBox(
                                          height: _heightAnimation.value,
                                          child: SingleChildScrollView(
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Header row: username and timestamp
                                                Row(
                                                  spacing: 8.0,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        user.name.isNotEmpty
                                                            ? user.name
                                                            : 'Unknown User',
                                                        overflow:
                                                            TextOverflow.fade,
                                                        style: NarwhalTextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: ThemeHelper
                                                              .neutral900(
                                                                  context),
                                                        ),
                                                      ),
                                                    ),
                                                    if (timeAgo.isNotEmpty) ...[
                                                      Flexible(
                                                        child: Text(
                                                          timeAgo,
                                                          overflow:
                                                              TextOverflow.fade,
                                                          style:
                                                              NarwhalTextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            color: ThemeHelper
                                                                    .neutral900(
                                                                        context)
                                                                .withValues(
                                                                    alpha: 0.7),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const Gap(4),
                                                Text(
                                                  widget.comment.text,
                                                  overflow: TextOverflow.fade,
                                                  softWrap: true,
                                                  style: NarwhalTextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        ThemeHelper.neutral900(
                                                            context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}
