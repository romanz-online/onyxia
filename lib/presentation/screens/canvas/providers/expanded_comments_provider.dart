import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpandedCommentsNotifier extends StateNotifier<Set<String>> {
  ExpandedCommentsNotifier() : super(<String>{});

  void expandComment(String commentId) {
    state = {...state, commentId};
  }

  void collapseComment(String commentId) {
    state = state.where((id) => id != commentId).toSet();
  }

  bool isCommentExpanded(String commentId) => state.contains(commentId);
}

final expandedCommentsProvider =
    StateNotifierProvider.autoDispose<ExpandedCommentsNotifier, Set<String>>((ref) => ExpandedCommentsNotifier());
