import 'package:onyxia/export.dart';

class HoverCommentContainer extends ConsumerStatefulWidget {
  final String hoveredCommentId;
  const HoverCommentContainer({super.key, required this.hoveredCommentId});

  @override
  ConsumerState<HoverCommentContainer> createState() => _HoverCommentContainerState();
}

class _HoverCommentContainerState extends ConsumerState<HoverCommentContainer> {
  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: Theme.of(context).cardColor,
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(
          maxWidth: 250,
          minWidth: 200,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ThemeHelper.black(context),
            width: 1,
          ),
        ),
        child: Builder(
          builder: (context) {
            final hoveredComment = ref
                .read(commentsProvider(ref.read(selectedArtifactProvider)?.id ?? '').notifier)
                .getCommentById(widget.hoveredCommentId);

            // Handle case where comment might not exist
            if (hoveredComment == null) {
              return const Center(
                child: Text(
                  'Comment not found',
                  style: NarwhalTextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: FutureBuilder<UserDefinition>(
                        future: ref.read(userLookupProvider).getUserById(hoveredComment.authorId),
                        builder: (context, snapshot) {
                          final author = snapshot.data ?? UserDefinition.initial();
                          return Text(
                            author.name,
                            style: const NarwhalTextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                    Text(
                      hoveredComment.timeAgo(),
                      style: NarwhalTextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: Text(
                    hoveredComment.text.isNotEmpty ? hoveredComment.text : 'No comment text',
                    style: NarwhalTextStyle(
                      fontSize: 12,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  hoveredComment.subComments.isEmpty
                      ? 'No replies'
                      : '${hoveredComment.subComments.length} ${hoveredComment.subComments.length == 1 ? 'reply' : 'replies'}',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
