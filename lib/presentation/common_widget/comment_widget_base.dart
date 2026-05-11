import 'package:onyxia/export.dart';

// Custom Intents for comment input keyboard actions
class NewLineIntent extends Intent {
  const NewLineIntent();
}

class SubmitIntent extends Intent {
  const SubmitIntent();
}

class CommentWidgetBase {
  static Widget buildNewCommentInput({
    required TextEditingController controller,
    required VoidCallback onSubmit,
    required VoidCallback onCancel,
    required String userName,
    required BuildContext context,
    FocusNode? focusNode,
    String? currentUserId,
  }) {
    // Extract user initials from userName
    String getUserInitials() {
      if (userName.trim().isEmpty) return '';
      final parts = userName.trim().split(RegExp(r'\s+'));
      final first = parts.isNotEmpty ? parts[0][0].toUpperCase() : '';
      final last = parts.length > 1 ? parts[1][0].toUpperCase() : '';
      return first + last;
    }

    return Container(
      width: 360,
      constraints: BoxConstraints(
        minHeight: 45,
      ),
      decoration: BoxDecoration(
        color: ThemeHelper.white(context),
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
            color: ThemeHelper.neutral900(context).withValues(alpha: 0.10),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with user initials
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ThemeHelper.red400(context),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                getUserInitials(),
                style: NarwhalTextStyle(
                  color: ThemeHelper.white(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                    final text = controller.text;
                    final selection = controller.selection;
                    final newText = text.replaceRange(selection.start, selection.end, '\n');
                    controller.value = controller.value.copyWith(
                      text: newText,
                      selection: TextSelection.collapsed(offset: selection.start + 1),
                    );
                    return null;
                  }),
                  SubmitIntent: CallbackAction<SubmitIntent>(onInvoke: (intent) {
                    onSubmit();
                    return null;
                  }),
                },
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const NarwhalTextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w400,
                  ),
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: ThemeHelper.neutral400(context),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: ThemeHelper.neutral400(context),
                        width: 1,
                      ),
                    ),
                    fillColor: ThemeHelper.neutral100(context),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/send.svg',
                      ),
                      onPressed: onSubmit,
                      tooltip: 'Send',
                      splashRadius: 20,
                    ),
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildCommentBox(
    BuildContext context,
    int commentIndex,
    Comment comment,
    TextEditingController controller,
    VoidCallback onSubmit,
    bool isHovered,
    String authorName, {
    List<ProjectMember>? availableUsers,
    String? currentUserId,
  }) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: ThemeHelper.white(context),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isHovered
            ? [
                BoxShadow(
                  color: ThemeHelper.neutral900(context).withValues(alpha: 0.26),
                  blurRadius: 5,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildCommentHeader(context, commentIndex, comment),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$authorName, ',
                        style: NarwhalTextStyle(
                          fontWeight: FontWeight.bold,
                          color: ThemeHelper.neutral900(context),
                        ),
                      ),
                      TextSpan(
                        text: comment.timeAgo(),
                        style: NarwhalTextStyle(color: ThemeHelper.neutral500(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(comment.text),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
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
                          final text = controller.text;
                          final selection = controller.selection;
                          final newText = text.replaceRange(selection.start, selection.end, '\n');
                          controller.value = controller.value.copyWith(
                            text: newText,
                            selection: TextSelection.collapsed(offset: selection.start + 1),
                          );
                          return null;
                        }),
                        SubmitIntent: CallbackAction<SubmitIntent>(onInvoke: (intent) {
                          onSubmit();
                          return null;
                        }),
                      },
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Reply',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: ThemeHelper.blue()),
                  onPressed: onSubmit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildCommentHeader(BuildContext context, int index, Comment comment) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#$index',
            style: NarwhalTextStyle.labelSmall(color: ThemeHelper.neutral600(context)),
          ),
          // Note: PopupMenuButton and close button would be handled by the parent widget
        ],
      ),
    );
  }
}
