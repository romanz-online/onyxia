import 'package:onyxia/export.dart';
import '../../../common_widget/comment_widget_base.dart';

enum CommentMenu { delete, edit }

enum SubCommentMenuAction { edit, delete }

class ArtifactComment extends ConsumerStatefulWidget {
  const ArtifactComment({
    super.key,
    required this.comment,
    this.localPosition,
    this.onClose,
    this.editorHeight,
    this.editorWidth,
  });

  final Comment comment;
  final Offset? localPosition;
  final VoidCallback? onClose;
  final double? editorHeight;
  final double? editorWidth;

  @override
  ConsumerState<ArtifactComment> createState() => _ArtifactCommentWidgetState();
}

class _ArtifactCommentWidgetState extends ConsumerState<ArtifactComment> {
  final TextEditingController _commentController = TextEditingController();
  late Offset _currentPosition;
  bool _showReplies = true;
  bool _isEditingComment = false;
  String? _editingSubCommentId;

  String get _selectedItemId => ref.read(selectedArtifactProvider)?.id ?? '';

  @override
  void initState() {
    super.initState();
    // Initialize with the widget's localPosition first
    final initialPosition = widget.localPosition ?? Offset.zero;

    // Validate position to ensure it fits within editor bounds
    // Use default dimensions for new comment (will be refined in didChangeDependencies)
    final isNewComment = widget.comment.text.isEmpty;
    final widgetWidth = isNewComment ? 240.0 : 500.0; // maxWidth from _buildCommentBox
    final widgetHeight = isNewComment ? 60.0 : 200.0; // Conservative estimate

    _currentPosition = _validatePosition(initialPosition, widgetWidth, widgetHeight);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now we can safely access the provider to get the stored position
    final storedPosition = _currentComment.position;
    if (storedPosition != null) {
      // Validate stored position to ensure it fits within current editor bounds
      final isNewComment = _currentComment.text.isEmpty;
      final widgetWidth = isNewComment ? 240.0 : 500.0; // maxWidth from _buildCommentBox
      final widgetHeight = isNewComment ? 60.0 : _calculateMaxHeight(context);

      _currentPosition = _validatePosition(storedPosition, widgetWidth, widgetHeight);
    }
  }

  @override
  void didUpdateWidget(ArtifactComment oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update position if the widget's comment changes
    if (oldWidget.comment.id != widget.comment.id) {
      final storedPosition = _currentComment.position;
      final rawPosition = storedPosition ?? widget.localPosition ?? Offset.zero;

      // Validate position when switching to a different comment
      final isNewComment = _currentComment.text.isEmpty;
      final widgetWidth = isNewComment ? 240.0 : 500.0; // maxWidth from _buildCommentBox
      final widgetHeight = isNewComment ? 60.0 : 200.0; // Conservative estimate

      _currentPosition = _validatePosition(rawPosition, widgetWidth, widgetHeight);

      // Only clear editing state when switching to a different comment
      setState(() {
        _isEditingComment = false;
        _editingSubCommentId = null;
        _commentController.clear();
      });
    }
  }

  void _updatePosition(DragUpdateDetails details) {
    setState(() {
      // Calculate desired new position
      final newPosition = _currentPosition + details.delta;

      // Calculate actual widget dimensions dynamically
      final isNewComment = _currentComment.text.isEmpty;
      final widgetWidth = isNewComment ? 240.0 : 500.0; // maxWidth from _buildCommentBox
      final widgetHeight = isNewComment ? 60.0 : _calculateMaxHeight(context);

      // Use centralized validation to constrain position within editor bounds
      _currentPosition = _validatePosition(newPosition, widgetWidth, widgetHeight);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    // Update the comment position in the provider
    final updatedComment = _currentComment.copyWith(
      position: _currentPosition,
    );
    ref.read(commentsProvider(_selectedItemId).notifier).updateComment(updatedComment: updatedComment);
  }

  bool get _isSelected {
    final selected = ref.watch(commentsProvider(_selectedItemId)).selectedComment;
    return selected.id == widget.comment.id;
  }

  // Get the current comment data from the provider
  Comment get _currentComment {
    final comments = ref.watch(commentsProvider(_selectedItemId)).comments;
    return comments.firstWhere(
      (c) => c.id == widget.comment.id,
      orElse: () => widget.comment, // Fallback to original comment if not found
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  double _calculateMaxHeight(BuildContext context) {
    // Use editor height if available, otherwise fall back to screen height
    final containerHeight = widget.editorHeight ?? MediaQuery.of(context).size.height;
    final topPadding = widget.editorHeight != null ? 0 : MediaQuery.of(context).padding.top;

    // Calculate available space considering current position
    final margin = 30.0;
    final availableHeight = containerHeight - _currentPosition.dy - margin - topPadding;

    // Use reasonable bounds with safe fallbacks
    const minHeight = 200.0;
    final preferredMaxHeight = containerHeight * 0.7;

    // Return a safe height that doesn't cause clamp errors
    if (availableHeight <= minHeight) {
      return minHeight; // Always return minimum when space is limited
    }

    return availableHeight.clamp(minHeight, preferredMaxHeight);
  }

  Offset _validatePosition(Offset desiredPosition, double widgetWidth, double widgetHeight) {
    final editorWidth = widget.editorWidth;
    final editorHeight = widget.editorHeight;

    // If editor bounds are not available, return desired position
    if (editorWidth == null || editorHeight == null) return desiredPosition;

    // Constrain to editor bounds considering widget size
    final constrainedX = desiredPosition.dx.clamp(0.0, (editorWidth - widgetWidth).clamp(0.0, double.infinity));
    final constrainedY = desiredPosition.dy.clamp(0.0, (editorHeight - widgetHeight).clamp(0.0, double.infinity));

    return Offset(constrainedX, constrainedY);
  }

  void _addSubComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      ref.read(commentsProvider(_selectedItemId).notifier).addSubComment(widget.comment.id, text);
      _commentController.clear();
    }
  }

  void _submitCommentText(String text) {
    _submitComment(
      existingComment: null,
      commentColor: _currentComment.color,
    );
  }

  void _startEditing() {
    setState(() {
      _isEditingComment = true;
      _commentController.text = _currentComment.text;
    });
  }

  void _saveEditedComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      final updatedComment = _currentComment.copyWith(text: text);
      ref.read(commentsProvider(_selectedItemId).notifier).updateComment(updatedComment: updatedComment);
      setState(() {
        _isEditingComment = false;
        _commentController.clear();
      });
      // Ensure edit intent is cleared
      ref.read(commentsProvider(_selectedItemId).notifier).clearEditIntent();
    }
  }

  void _cancelEditingComment() {
    setState(() {
      _isEditingComment = false;
      _editingSubCommentId = null;
      _commentController.clear();
    });
    // Ensure edit intent is cleared
    ref.read(commentsProvider(_selectedItemId).notifier).clearEditIntent();
  }

  void _deleteSubComment(String subCommentId) {
    ref.read(commentsProvider(_selectedItemId).notifier).deleteSubComment(widget.comment.id, subCommentId);
  }

  void _startEditingSubComment(SubComment subComment) {
    setState(() {
      _editingSubCommentId = subComment.id;
      _commentController.text = subComment.text;
    });
  }

  void _saveEditedSubComment() {
    if (_editingSubCommentId != null) {
      final text = _commentController.text.trim();
      if (text.isNotEmpty) {
        ref.read(commentsProvider(_selectedItemId).notifier).updateSubComment(
              commentId: widget.comment.id,
              subCommentId: _editingSubCommentId!,
              text: text,
            );
        setState(() {
          _editingSubCommentId = null;
          _commentController.clear();
        });
        // Ensure edit intent is cleared
        ref.read(commentsProvider(_selectedItemId).notifier).clearEditIntent();
      }
    }
  }

  void _cancelEditingSubComment() {
    setState(() {
      _editingSubCommentId = null;
      _commentController.clear();
    });
    // Ensure edit intent is cleared
    ref.read(commentsProvider(_selectedItemId).notifier).clearEditIntent();
  }

  Widget _buildSubCommentsList() {
    if (_currentComment.subComments.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _currentComment.subComments.length; i++) ...[
          if (i > 0) const Divider(indent: 5, endIndent: 5, height: 1),
          _buildSubCommentItem(_currentComment.subComments[i]),
        ],
      ],
    );
  }

  Widget _buildSubCommentItem(SubComment subComment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        FutureBuilder<UserDefinition>(
                          future: ref.read(userLookupProvider).getUserById(subComment.authorId),
                          builder: (context, snapshot) {
                            final author = snapshot.data ?? UserDefinition.initial();
                            return Text(
                              '${author.name},',
                              style: NarwhalTextStyle(
                                fontWeight: FontWeight.w700,
                                color: ThemeHelper.neutral900(context),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          subComment.timeAgo(),
                          style: NarwhalTextStyle(
                            color: ThemeHelper.neutral500(context),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<SubCommentMenuAction>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert, size: 18),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: SubCommentMenuAction.edit,
                          child: Row(
                            children: const [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: SubCommentMenuAction.delete,
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: ThemeHelper.red()),
                              SizedBox(width: 8),
                              Text('Delete', style: NarwhalTextStyle(color: ThemeHelper.red())),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (action) {
                        switch (action) {
                          case SubCommentMenuAction.edit:
                            _startEditingSubComment(subComment);
                            break;
                          case SubCommentMenuAction.delete:
                            _deleteSubComment(subComment.id);
                            break;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subComment.text,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: const NarwhalTextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Builds the comment header with index, menu, and close button
  Widget _buildCommentHeader(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.drag_indicator, size: 16, color: ThemeHelper.neutral500(context)),
            const SizedBox(width: 4),
            CommentWidgetBase.buildCommentHeader(context, index, _currentComment),
          ],
        ),
        Row(
          children: [
            PopupMenuButton<CommentMenu>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, size: 18),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: CommentMenu.edit,
                  onTap: _startEditing,
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: CommentMenu.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: ThemeHelper.red()),
                      SizedBox(width: 8),
                      Text('Delete', style: NarwhalTextStyle(color: ThemeHelper.red())),
                    ],
                  ),
                  onTap: () {
                    ref.read(commentsProvider(_selectedItemId).notifier).deleteComment(commentId: _currentComment.id);
                    widget.onClose?.call();
                  },
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_sharp, size: 18),
              onPressed: () {
                ref.read(commentsProvider(_selectedItemId).notifier).setSelectedComment(null);
                widget.onClose?.call();
              },
            ),
          ],
        ),
      ],
    );
  }

  // Builds the comment box with custom header
  Widget _buildCommentBox(int commentIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            minWidth: 300,
            maxWidth: 500,
            maxHeight: _calculateMaxHeight(context),
          ),
          padding: const EdgeInsets.only(top: 4, right: 8, bottom: 8, left: 8),
          decoration: BoxDecoration(
            color: ThemeHelper.white(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ThemeHelper.neutral400(context),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: ThemeHelper.neutral900(context).withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, innerConstraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCommentHeader(commentIndex),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              FutureBuilder<UserDefinition>(
                                future: ref.read(userLookupProvider).getUserById(_currentComment.authorId),
                                builder: (context, snapshot) {
                                  final author = snapshot.data ?? UserDefinition.initial();
                                  return Text(
                                    '${author.name},',
                                    style: NarwhalTextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: ThemeHelper.neutral900(context),
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _currentComment.timeAgo(),
                                style: NarwhalTextStyle(
                                  color: ThemeHelper.neutral900(context),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentComment.text,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                          if (_currentComment.subComments.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showReplies = !_showReplies;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showReplies ? Icons.expand_less : Icons.expand_more,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _showReplies
                                        ? 'Hide ${_currentComment.subComments.length} ${_currentComment.subComments.length == 1 ? "reply" : "replies"}'
                                        : 'Show ${_currentComment.subComments.length} ${_currentComment.subComments.length == 1 ? "reply" : "replies"}',
                                    style: const NarwhalTextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_showReplies && _currentComment.subComments.isNotEmpty) ...[
                            const Divider(height: 16),
                            _buildSubCommentsList(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: ThemeHelper.neutral300(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Shortcuts(
                            shortcuts: <LogicalKeySet, Intent>{
                              LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter): const NewLineIntent(),
                              LogicalKeySet(LogicalKeyboardKey.enter): const SubmitIntent(),
                            },
                            child: Actions(
                              actions: <Type, Action<Intent>>{
                                NewLineIntent: CallbackAction<NewLineIntent>(onInvoke: (intent) {
                                  // Insert newline manually at cursor position
                                  final text = _commentController.text;
                                  final selection = _commentController.selection;
                                  final newText = text.replaceRange(selection.start, selection.end, '\n');
                                  _commentController.value = _commentController.value.copyWith(
                                    text: newText,
                                    selection: TextSelection.collapsed(offset: selection.start + 1),
                                  );
                                  return null;
                                }),
                                SubmitIntent: CallbackAction<SubmitIntent>(onInvoke: (intent) {
                                  if (_isEditingComment) {
                                    _saveEditedComment();
                                  } else if (_editingSubCommentId != null) {
                                    _saveEditedSubComment();
                                  } else {
                                    _addSubComment();
                                  }
                                  return null;
                                }),
                              },
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: _isEditingComment
                                      ? 'Edit comment'
                                      : _editingSubCommentId != null
                                          ? 'Edit reply'
                                          : 'Reply',
                                  border: InputBorder.none,
                                  hintStyle: NarwhalTextStyle(color: ThemeHelper.neutral500(context)),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                              ),
                            ),
                          ),
                        ),
                        if (_isEditingComment) ...[
                          IconButton(
                            icon: Icon(Icons.close, color: ThemeHelper.neutral500(context)),
                            onPressed: _cancelEditingComment,
                            tooltip: 'Cancel',
                            splashRadius: 20,
                          ),
                          IconButton(
                            icon: Icon(Icons.check, color: ThemeHelper.green()),
                            onPressed: _saveEditedComment,
                            tooltip: 'Save',
                            splashRadius: 20,
                          ),
                        ] else if (_editingSubCommentId != null) ...[
                          IconButton(
                            icon: Icon(Icons.close, color: ThemeHelper.neutral500(context)),
                            onPressed: _cancelEditingSubComment,
                            tooltip: 'Cancel',
                            splashRadius: 20,
                          ),
                          IconButton(
                            icon: Icon(Icons.check, color: ThemeHelper.green()),
                            onPressed: _saveEditedSubComment,
                            tooltip: 'Save',
                            splashRadius: 20,
                          ),
                        ] else
                          IconButton(
                            icon: Icon(Icons.send, color: ThemeHelper.neutral500(context)),
                            onPressed: _addSubComment,
                            tooltip: 'Send',
                            splashRadius: 20,
                          ),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentIndex = ref.watch(commentsProvider(_selectedItemId).notifier).getCommentIndex(_currentComment);
    final user = ref.watch(currentUserProvider);

    final showExpanded = _isSelected || _currentComment.text.isEmpty;

    // Watch for edit intent changes
    final state = ref.watch(commentsProvider(_selectedItemId));
    if (state.shouldEditOnOpen && state.selectedComment.id == widget.comment.id) {
      // Check if we need to switch what we're editing
      final needsUpdate = state.editingSubCommentId != _editingSubCommentId ||
          (state.editingSubCommentId == null && !_isEditingComment);

      if (needsUpdate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Clear current editing state first
            setState(() {
              _isEditingComment = false;
              _editingSubCommentId = null;
              _commentController.clear();
            });

            if (state.editingSubCommentId != null) {
              // Find and start editing the specific subcomment
              final subComment = _currentComment.subComments.firstWhere(
                (sc) => sc.id == state.editingSubCommentId,
                orElse: () => SubComment(id: '', text: '', authorId: '', createdAt: DateTime.now()),
              );
              if (subComment.id.isNotEmpty) {
                _startEditingSubComment(subComment);
              }
            } else {
              _startEditing();
            }
            // Reset the edit intent by clearing the flag but keeping the selection
            ref.read(commentsProvider(_selectedItemId).notifier).clearEditIntent();
          }
        });
      }
    }

    return Positioned(
      left: _currentPosition.dx,
      top: _currentPosition.dy + 25.00,
      child: MouseRegion(
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: GestureDetector(
            onPanUpdate: _updatePosition,
            onPanEnd: _onDragEnd,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showExpanded)
                  (_currentComment.text.isEmpty)
                      ? CommentWidgetBase.buildNewCommentInput(
                          controller: _commentController,
                          onSubmit: () => _submitCommentText(_commentController.text),
                          onCancel: () {
                            _commentController.clear();
                            // Clear selected comment before closing
                            ref.read(commentsProvider(_selectedItemId).notifier).setSelectedComment(null);
                            widget.onClose?.call();
                          },
                          userName: user.name,
                          context: context,
                          currentUserId: ref.read(currentUserProvider).id,
                        )
                      : _buildCommentBox(commentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitComment({
    Comment? existingComment,
    required Color commentColor,
  }) {
    if (_commentController.text.isEmpty) {
      NarwhalToast.show(
        text: 'Comment cannot be empty',
        type: ToastType.warning,
      );
      return;
    }

    try {
      final commentId = existingComment?.id ?? widget.comment.id;
      if (existingComment == null) {
        ref.read(commentsProvider(_selectedItemId).notifier).addComment(
              text: _commentController.text,
              commentId: commentId,
              color: commentColor,
              position: widget.comment.position,
              targetType: CommentTargetType.note,
            );
        // Clear selection and notify Editor to close the widget
        ref.read(commentsProvider(_selectedItemId).notifier).setSelectedComment(null);
        widget.onClose?.call();
      } else {
        final updatedComment = existingComment.copyWith(
          text: _commentController.text,
          createdAt: DateTime.now(),
        );
        ref.read(commentsProvider(_selectedItemId).notifier).updateComment(
              updatedComment: updatedComment,
            );
      }

      NarwhalToast.show(
        text: 'Comment processed successfully',
        type: ToastType.success,
      );

      _commentController.clear();
    } catch (error) {
      NarwhalToast.show(
        text: 'Failed to process comment: $error',
        type: ToastType.error,
      );
    }
  }
}
