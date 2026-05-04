import 'package:onyxia/export.dart';

enum SubCommentMenuAction { edit, delete }

class SubCommentListTile extends ConsumerWidget {
  final SubComment subComment;
  final String? currentUserId;
  final Function(SubComment) onEdit;
  final Function(SubComment) onDelete;
  final bool showMenuForAllUsers;

  const SubCommentListTile({
    super.key,
    required this.subComment,
    required this.onEdit,
    required this.onDelete,
    this.currentUserId,
    this.showMenuForAllUsers = true,
  });

  bool get _shouldShowMenu {
    if (showMenuForAllUsers) return true;
    return currentUserId != null && subComment.authorId == currentUserId;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.only(right: 8, bottom: 8),
      title: Row(
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
                      color: ThemeHelper.black(context),
                      fontSize: 12,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                subComment.timeAgo(),
                style: NarwhalTextStyle(
                  color: ThemeHelper.black(context),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (_shouldShowMenu)
            PopupMenuButton<SubCommentMenuAction>(
              padding: EdgeInsets.zero,
              icon: const NarwhalIcon(NarwhalIcons.moreDots, size: 18),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: SubCommentMenuAction.edit,
                  child: Row(
                    children: const [
                      NarwhalIcon(NarwhalIcons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SubCommentMenuAction.delete,
                  child: Row(
                    children: [
                      NarwhalIcon(
                        NarwhalIcons.delete,
                        size: 18,
                        color: ThemeHelper.red(),
                      ),
                      SizedBox(width: 8),
                      Text('Delete', style: NarwhalTextStyle(color: ThemeHelper.red())),
                    ],
                  ),
                ),
              ],
              onSelected: (action) {
                switch (action) {
                  case SubCommentMenuAction.edit:
                    onEdit(subComment);
                    break;
                  case SubCommentMenuAction.delete:
                    onDelete(subComment);
                    break;
                }
              },
            ),
        ],
      ),
      subtitle: Text(subComment.text),
    );
  }
}
