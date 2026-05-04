import 'package:onyxia/export.dart';
import 'comment_item.dart';

class CommentList extends ConsumerStatefulWidget {
  final List<Comment> comments;
  final String targetId;

  const CommentList({
    super.key,
    required this.comments,
    required this.targetId,
  });

  @override
  CommentListState createState() => CommentListState();
}

class CommentListState extends ConsumerState<CommentList> {
  final ScrollController _scrollController = ScrollController();
  String? _lastSelectedCommentId;
  final Map<String, GlobalKey> _commentKeys = {};

  void toggleSelection(Comment comment) {
    final selected = ref.read(commentsProvider(widget.targetId)).selectedComment;
    final isAlreadySelected = selected.id == comment.id;
    ref.read(commentsProvider(widget.targetId).notifier).setSelectedComment(
          isAlreadySelected ? null : comment,
        );
  }

  @override
  void initState() {
    super.initState();
    // Initialize the last selected comment ID
    _lastSelectedCommentId = ref.read(commentsProvider(widget.targetId)).selectedComment.id;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show empty state if no comments
    if (widget.comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NarwhalIcon(
                NarwhalIcons.comment,
                size: 48,
                color: ThemeHelper.neutral500(context),
              ),
              const SizedBox(height: 16),
              Text(
                'No comments yet',
                style: NarwhalTextStyle(
                  fontSize: 16,
                  color: ThemeHelper.neutral500(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select text to add a comment',
                style: NarwhalTextStyle(
                  fontSize: 14,
                  color: ThemeHelper.neutral500(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Watch the provider to get the selected comment
    final selectedComment = ref.watch(commentsProvider(widget.targetId)).selectedComment;

    // Scroll to the selected comment if it changes
    if (selectedComment.id.isNotEmpty && selectedComment.id != _lastSelectedCommentId) {
      final targetKey = _commentKeys[selectedComment.id]; // Get key for selected comment

      if (targetKey != null && targetKey.currentContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            Scrollable.ensureVisible(
              targetKey.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.0,
            );
          }
        });
      }
      _lastSelectedCommentId = selectedComment.id;
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.comments.length,
      itemBuilder: (context, index) {
        final comment = widget.comments[index];
        _commentKeys.putIfAbsent(comment.id, () => GlobalKey());
        final commentKey = _commentKeys[comment.id]!;

        final commentIndex = ref.read(commentsProvider(widget.targetId).notifier).getCommentIndex(comment);

        return CommentItem(
          key: commentKey,
          comment: comment,
          selectedCommentId: selectedComment.id, // Use the watched value
          onSelect: toggleSelection,
          index: commentIndex,
          targetId: widget.targetId,
        );
      },
    );
  }
}
