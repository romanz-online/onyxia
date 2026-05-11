import 'package:onyxia/export.dart';

class CommentsState {
  final List<Comment> comments;
  final bool shouldEditOnOpen;
  final String? editingSubCommentId;
  final Comment? temporaryComment;
  final String? objectId;

  CommentsState({
    required this.comments,
    this.shouldEditOnOpen = false,
    this.editingSubCommentId,
    this.temporaryComment,
    this.objectId,
  });

  factory CommentsState.initial() {
    return CommentsState(comments: []);
  }

  CommentsState copyWith({
    List<Comment>? comments,
    bool? shouldEditOnOpen,
    String? editingSubCommentId,
    Comment? temporaryComment,
    String? objectId,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      shouldEditOnOpen: shouldEditOnOpen ?? false,
      editingSubCommentId: editingSubCommentId,
      temporaryComment: temporaryComment,
      objectId: objectId,
    );
  }
}

final commentsProvider =
    StateNotifierProvider.family<CommentsNotifier, CommentsState, String>(
        (ref, targetId) {
  final projectId = ref.watch(projectsProvider).selectedProject.id;
  final repository = CommentsRepository(projectId: projectId);

  return CommentsNotifier(
    repository: repository,
    projectId: projectId,
    targetId: targetId,
    user: ref.watch(currentUserProvider),
    ref: ref,
  );
});

class CommentsNotifier extends StateNotifier<CommentsState> {
  final CommentsRepository repository;
  final String projectId;
  final String targetId;
  final UserDefinition user;
  final Ref ref;
  StreamSubscription<List<Comment>>? _subscription;

  CommentsNotifier({
    required this.repository,
    required this.projectId,
    required this.targetId,
    required this.user,
    required this.ref,
  }) : super(CommentsState.initial()) {
    _watchComments();
  }

  void _watchComments() {
    _subscription?.cancel();
    _subscription =
        repository.watchComments(targetId: targetId).listen((comments) {
      final sortedComments = List<Comment>.from(comments);
      sortedComments.sort((a, b) => (a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

      state = state.copyWith(comments: sortedComments);
    }, onError: (error) {
      debugPrint('Error watching comments: $error');
    });
  }

  Comment? getCommentById(String commentId) {
    try {
      return state.comments.firstWhere((comment) => comment.id == commentId);
    } catch (e) {
      // If the comment is not found in the state, return null
      return null;
    }
  }

  Future<void> addComment({
    required String text,
    required String commentId,
    required Offset position,
  }) async {
    final newComment = Comment(
      id: commentId,
      text: text,
      subComments: [],
      createdBy: user.id,
      position: position,
    );

    await repository.addComment(targetId: targetId, comment: newComment);
  }

  Future<void> updateComment({
    required Comment updatedComment,
    Offset? delta,
  }) async {
    Comment newComment = updatedComment;

    if (delta != null) {
      newComment = updatedComment.copyWith(
        position: updatedComment.position + delta,
      );
    }

    await repository.updateComment(targetId: targetId, comment: newComment);

    // Update local state
    state = state.copyWith(
      comments: [
        for (final comment in state.comments)
          if (comment.id == newComment.id) newComment else comment
      ],
    );
  }

  Future<void> deleteComment({required String commentId}) async =>
      await repository.delete(commentId);

  Future<void> addSubComment(String commentId, String text) async {
    final comment = state.comments.firstWhere((c) => c.id == commentId);
    final subComment = SubComment(
      id: const Uuid().v4(),
      content: text,
      createdBy: user.id,
      createdAt: DateTime.now(),
    );

    final updatedComment = comment.copyWith(
      subComments: [...comment.subComments, subComment],
    );

    await repository.updateComment(
      targetId: targetId,
      comment: updatedComment,
    );
  }

  Future<void> updateSubComment({
    required String commentId,
    required String subCommentId,
    required String text,
  }) async {
    final comment = state.comments.firstWhere((c) => c.id == commentId);

    // Find and update the specific subcomment
    final updatedSubComments = comment.subComments.map((subComment) {
      if (subComment.id == subCommentId) {
        return subComment.copyWith(content: text);
      }
      return subComment;
    }).toList();

    final updatedComment = comment.copyWith(
      subComments: updatedSubComments,
    );

    await repository.updateComment(
      targetId: targetId,
      comment: updatedComment,
    );
  }

  Future<void> deleteSubComment(String commentId, String subCommentId) async {
    final comment = state.comments.firstWhere((c) => c.id == commentId);
    final updatedSubComments =
        comment.subComments.where((sub) => sub.id != subCommentId).toList();

    final updatedComment = comment.copyWith(subComments: updatedSubComments);

    await repository.updateComment(
      targetId: targetId,
      comment: updatedComment,
    );
  }

  // Move a comment's position locally (for canvas comments)
  void moveCommentLocally(String commentId, Offset delta) {
    state = state.copyWith(
      comments: [
        for (final comment in state.comments)
          if (comment.id == commentId)
            comment.copyWith(position: comment.position + delta)
          else
            comment
      ],
    );
  }

  // Get the 1-based index of a comment based on creation time
  int getCommentIndex(Comment comment) {
    final sortedComments = List<Comment>.from(state.comments);
    sortedComments.sort((a, b) =>
        (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return sortedComments.indexOf(comment) + 1; // 1-based index
  }

  // Clear edit intent while keeping the selected comment
  void clearEditIntent() {
    state = state.copyWith(
      shouldEditOnOpen: false,
      editingSubCommentId: null,
    );
  }

  // Create a temporary comment (not saved to Firebase until text is provided)
  void createTemporaryComment({
    required String commentId,
    required Offset position,
    String? objectId,
    String? pinnedObjectId,
  }) {
    final tempComment = Comment(
      id: commentId,
      text: '',
      subComments: [],
      createdBy: user.id,
      position: position,
      pinnedObjectId: pinnedObjectId,
    );

    state = state.copyWith(
      temporaryComment: tempComment,
      objectId: objectId,
    );
  }

  // Save temporary comment to Firebase with actual text
  Future<void> saveTemporaryComment(WidgetRef ref, String text) async {
    if (state.temporaryComment == null || text.trim().isEmpty) {
      clearTemporaryComment();
      return;
    }

    final commentToSave = state.temporaryComment!.copyWith(text: text.trim());

    await repository.addComment(
      targetId: targetId,
      comment: commentToSave,
    );

    clearTemporaryComment();
  }

  // Clear temporary comment without saving
  void clearTemporaryComment() {
    state = state.copyWith(temporaryComment: null, objectId: null);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
