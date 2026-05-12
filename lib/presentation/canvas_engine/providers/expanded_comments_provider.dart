import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpandedCommentsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void expandComment(String commentId) {
    state = {...state, commentId};
  }

  void collapseComment(String commentId) {
    state = state.where((id) => id != commentId).toSet();
  }

  bool isCommentExpanded(String commentId) => state.contains(commentId);
}

final expandedCommentsProvider =
    NotifierProvider.autoDispose<ExpandedCommentsNotifier, Set<String>>(
  ExpandedCommentsNotifier.new,
);
