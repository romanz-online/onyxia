import 'package:onyxia/export.dart';
import 'sub_comment_list_tile.dart';

class SubCommentListView extends StatelessWidget {
  final List<SubComment> subComments;
  final Function(SubComment) onEdit;
  final Function(SubComment) onDelete;
  final String? currentUserId;
  final bool showMenuForAllUsers;
  final double height;

  const SubCommentListView({
    super.key,
    required this.subComments,
    required this.onEdit,
    required this.onDelete,
    required this.height,
    this.currentUserId,
    this.showMenuForAllUsers = true,
  });

  @override
  Widget build(BuildContext context) {
    if (subComments.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        separatorBuilder: (context, index) => const Divider(
          indent: 5,
          endIndent: 5,
          height: 1,
        ),
        shrinkWrap: true,
        itemCount: subComments.length,
        itemBuilder: (context, index) {
          final subComment = subComments[index];

          return SubCommentListTile(
            subComment: subComment,
            currentUserId: currentUserId,
            onEdit: onEdit,
            onDelete: onDelete,
            showMenuForAllUsers: showMenuForAllUsers,
          );
        },
      ),
    );
  }
}
