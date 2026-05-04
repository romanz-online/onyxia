import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/screens/canvas/providers/providers.dart';

class CommentItem extends ConsumerStatefulWidget {
  final Comment comment;
  final String? selectedCommentId;
  final Function(Comment) onSelect;
  final int index;
  final String targetId;

  const CommentItem({
    super.key,
    required this.comment,
    required this.selectedCommentId,
    required this.onSelect,
    required this.index,
    required this.targetId,
  });

  @override
  ConsumerState<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<CommentItem> {
  bool showSubComments = false;
  bool _isHovered = false;
  bool _isSelected = false;

  final Map<String, UserDefinition> _userCache = {};

  Future<UserDefinition> _getUser(String userId) async {
    if (userId.isEmpty) return UserDefinition.initial();

    if (_userCache.containsKey(userId)) return _userCache[userId]!;

    try {
      if (!mounted) return UserDefinition.initial();
      final user = await ref.read(userLookupProvider).getUserById(userId);
      if (!mounted) return UserDefinition.initial();
      _userCache[userId] = user;
      return user;
    } catch (e) {
      if (!mounted) return UserDefinition.initial();
      final fallbackUser = UserDefinition.initial().copyWith(name: userId, id: userId);
      _userCache[userId] = fallbackUser;
      return fallbackUser;
    }
  }

  void _handleCommentAction(String action, Comment comment) {
    switch (action) {
      case 'Reply':
        debugPrint('Reply to comment: ${comment.id}');
        widget.onSelect(widget.comment);
        break;
      case 'Edit':
        debugPrint('Editing comment: ${comment.id}');
        _showEditCommentDialog(comment);
        break;
      case 'Delete':
        debugPrint('Deleting comment: ${comment.id}');
        _showDeleteConfirmationDialog(
          title: 'Delete Comment',
          content: 'Are you sure you want to delete this comment?',
          onConfirm: () {
            ref.read(commentsProvider(widget.targetId).notifier).deleteComment(commentId: comment.id).then(
              (value) {
                NarwhalToast.show(
                  text: 'Comment deleted',
                  type: ToastType.info,
                );
              },
            );
          },
        );
        break;
    }
  }

  void _handleSubCommentAction(
    String action,
    Comment parentComment,
    SubComment subComment,
  ) {
    switch (action) {
      case 'Edit':
        debugPrint('Editing subcomment: ${subComment.id} of comment: ${parentComment.id}');
        _showEditSubCommentDialog(parentComment, subComment);
        break;
      case 'Delete':
        debugPrint('Deleting subcomment: ${subComment.id} of comment: ${parentComment.id}');
        _showDeleteConfirmationDialog(
          title: 'Delete Reply',
          content: 'Are you sure you want to delete this reply?',
          onConfirm: () {
            ref
                .read(commentsProvider(widget.targetId).notifier)
                .deleteSubComment(
                  parentComment.id,
                  subComment.id,
                )
                .then(
              (value) {
                NarwhalToast.show(
                  text: 'Reply deleted',
                  type: ToastType.info,
                );
              },
            );
          },
        );
        break;
    }
  }

  void _showEditCommentDialog(Comment comment) {
    ref.read(commentsProvider(widget.targetId).notifier).setSelectedCommentForEdit(comment);
  }

  void _showEditSubCommentDialog(Comment parentComment, SubComment subComment) {
    ref.read(commentsProvider(widget.targetId).notifier).setSelectedCommentForEdit(
          parentComment,
          subCommentId: subComment.id,
        );
  }

  void _showDeleteConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: ThemeHelper.red()),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<String> _getAvailableCommentActions() {
    final currentUser = ref.read(currentUserProvider);
    final List<String> availableActions = ['Reply'];

    // Only show Edit/Delete if current user is the comment author
    if (currentUser.id == widget.comment.authorId) {
      availableActions.addAll(['Edit', 'Delete']);
    }

    return availableActions;
  }

  List<String> _getAvailableSubCommentActions(SubComment subComment) {
    final currentUser = ref.read(currentUserProvider);
    final List<String> availableActions = [];

    // Only show Edit/Delete if current user is the subcomment author
    if (currentUser.id == subComment.authorId) {
      availableActions.addAll(['Edit', 'Delete']);
    }

    return availableActions;
  }

  Widget _buildPopupMenuButton({
    required List<String> actions,
    required Function(String) onSelected,
    double iconSize = 20,
  }) {
    return PopupMenuButton<String>(
      icon: NarwhalIcon(NarwhalIcons.moreDots, size: iconSize),
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) => actions.map((String action) {
        return PopupMenuItem<String>(
          value: action,
          child: Row(
            children: [
              NarwhalIcon(
                action == 'Reply'
                    ? NarwhalIcons.backArrow
                    : action == 'Edit'
                        ? NarwhalIcons.edit
                        : NarwhalIcons.delete,
                size: 16,
                color: action == 'Delete' ? ThemeHelper.red() : null,
              ),
              const SizedBox(width: 8),
              Text(
                action,
                style: action == 'Delete' ? NarwhalTextStyle(color: ThemeHelper.red()) : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableCommentActions = _getAvailableCommentActions();
    final replyCount = widget.comment.subComments.length;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _isSelected = !_isSelected;
          });
        },
        child: Container(
          color: _isSelected ? ThemeHelper.blue500(context).withValues(alpha: 0.3) : null,
          padding: const EdgeInsets.all(12),
          child: FutureBuilder<UserDefinition>(
            future: _getUser(widget.comment.authorId),
            builder: (context, snapshot) {
              final user = snapshot.data ?? UserDefinition.initial();

              return Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.comment.resolved)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ThemeHelper.neutral400(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Resolved',
                                  style: NarwhalTextStyle(
                                    fontSize: 12,
                                    color: ThemeHelper.neutral100(context),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Segoe UI',
                                  ),
                                ),
                              )
                            else if (_isSelected || _isHovered)
                              Row(
                                children: [
                                  NarwhalIconButton(
                                    icon: NarwhalIcons.resolve,
                                    onPressed: () {
                                      final resolvedComment = widget.comment.copyWith(resolved: true);
                                      ref
                                          .read(commentsProvider(widget.targetId).notifier)
                                          .updateComment(updatedComment: resolvedComment);
                                    },
                                    size: 32,
                                    iconSafeMode: true,
                                    tooltip: 'Mark as Resolved',
                                  ),
                                  NarwhalIconButton(
                                    onPressed: () {
                                      ref.read(expandedPinProvider.notifier).expandPin(widget.comment);
                                    },
                                    enabled: !widget.comment.resolved,
                                    icon: NarwhalIcons.comment,
                                    size: 32,
                                    tooltip: "Expand Comment Pin",
                                  )
                                ],
                              ),
                            if (_isSelected || _isHovered)
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: _buildPopupMenuButton(
                                  actions: availableCommentActions,
                                  onSelected: (action) => _handleCommentAction(action, widget.comment),
                                ),
                              )
                            else
                              const SizedBox(width: 48, height: 48), // Placeholder for menu button
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#${widget.index + 1}',
                      style: NarwhalTextStyle(
                        fontSize: 12,
                        color: ThemeHelper.neutral800(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name.isNotEmpty ? user.name : 'Unknown User',
                          style: NarwhalTextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: ThemeHelper.neutral800(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.comment.timeAgo(),
                          style: NarwhalTextStyle(
                            fontSize: 12,
                            color: ThemeHelper.neutral500(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 250,
                      child: Text(
                        widget.comment.text,
                        style: NarwhalTextStyle(
                          fontSize: 12,
                          color: ThemeHelper.neutral800(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (replyCount > 0)
                      InkWell(
                        onTap: () {
                          setState(() {
                            showSubComments = !showSubComments;
                          });
                        },
                        child: Text(
                          showSubComments
                              ? 'Hide ${replyCount == 1 ? 'Reply' : 'Replies'}'
                              : '$replyCount ${replyCount == 1 ? 'Reply' : 'Replies'}',
                          style: NarwhalTextStyle(
                            fontSize: 12,
                            color: ThemeHelper.neutral500(context),
                          ),
                        ),
                      ),
                    if (showSubComments && widget.comment.subComments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 0.0, top: 12),
                        child: Column(
                          children: widget.comment.subComments.asMap().entries.map((entry) {
                            final subComment = entry.value;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FutureBuilder<UserDefinition>(
                                future: _getUser(subComment.authorId),
                                builder: (context, snapshot) {
                                  final user = snapshot.data ?? UserDefinition.initial();

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: NarwhalIcon(
                                          NarwhalIcons.indent,
                                          size: 24,
                                          color: ThemeHelper.neutral500(context),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                user.name.isNotEmpty ? user.name : 'Unknown User',
                                                style: NarwhalTextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: ThemeHelper.neutral800(context),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                subComment.timeAgo(),
                                                style: NarwhalTextStyle(
                                                  fontSize: 11,
                                                  color: ThemeHelper.neutral500(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: 220,
                                            child: Text(
                                              subComment.text,
                                              style: NarwhalTextStyle(
                                                fontSize: 12,
                                                color: ThemeHelper.neutral800(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      () {
                                        final availableSubCommentActions = _getAvailableSubCommentActions(subComment);
                                        if (availableSubCommentActions.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return _buildPopupMenuButton(
                                          actions: availableSubCommentActions,
                                          onSelected: (action) => _handleSubCommentAction(
                                            action,
                                            widget.comment,
                                            subComment,
                                          ),
                                          iconSize: 18,
                                        );
                                      }(),
                                    ],
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
