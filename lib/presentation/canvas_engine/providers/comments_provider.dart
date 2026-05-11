import 'package:onyxia/export.dart';
import 'objects_provider.dart';

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
    StateNotifierProvider.autoDispose<CommentsNotifier, CommentsState>((ref) {
  final canvasId = ref.watch(currentCanvasProvider.select((c) => c?.id ?? ''));
  final projectId = ref.watch(projectsProvider).selectedProject?.id;
  return CommentsNotifier(
    CommentsState.initial(),
    repository: CommentsRepository(
      projectId: projectId,
      canvasId: canvasId,
    ),
    canvasId: canvasId,
    projectId: projectId,
    user: ref.watch(currentUserProvider),
  );
});

class CommentsNotifier extends StateNotifier<CommentsState> {
  final CommentsRepository repository;
  final String canvasId;
  final String? projectId;
  final User user;
  StreamSubscription<List<Comment>>? _subscription;

  CommentsNotifier(
    super.state, {
    required this.repository,
    required this.canvasId,
    required this.projectId,
    required this.user,
  }) {
    _init();
  }

  void _init() {
    if (canvasId.isEmpty || projectId == null) return;

    _subscription = repository.getStream().listen((comments) {
      if (!mounted) return;
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
      canvasId: canvasId,
    );

    await repository.add([newComment]);
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

    await repository.update(newComment.copyWith(canvasId: canvasId));

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

    await repository.update(updatedComment.copyWith(canvasId: canvasId));
  }

  Future<void> updateSubComment({
    required String commentId,
    required String subCommentId,
    required String text,
  }) async {
    final comment = state.comments.firstWhere((c) => c.id == commentId);

    final updatedSubComments = comment.subComments.map((subComment) {
      if (subComment.id == subCommentId) {
        return subComment.copyWith(content: text);
      }
      return subComment;
    }).toList();

    final updatedComment = comment.copyWith(
      subComments: updatedSubComments,
    );

    await repository.update(updatedComment.copyWith(canvasId: canvasId));
  }

  Future<void> deleteSubComment(String commentId, String subCommentId) async {
    final comment = state.comments.firstWhere((c) => c.id == commentId);
    final updatedSubComments =
        comment.subComments.where((sub) => sub.id != subCommentId).toList();

    final updatedComment = comment.copyWith(subComments: updatedSubComments);

    await repository.update(updatedComment.copyWith(canvasId: canvasId));
  }

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

  int getCommentIndex(Comment comment) {
    final sortedComments = List<Comment>.from(state.comments);
    sortedComments.sort((a, b) =>
        (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return sortedComments.indexOf(comment) + 1;
  }

  void clearEditIntent() {
    state = state.copyWith(
      shouldEditOnOpen: false,
      editingSubCommentId: null,
    );
  }

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
      canvasId: canvasId,
    );

    state = state.copyWith(
      temporaryComment: tempComment,
      objectId: objectId,
    );
  }

  Future<void> saveTemporaryComment(String text) async {
    if (state.temporaryComment == null || text.trim().isEmpty) {
      clearTemporaryComment();
      return;
    }

    final commentToSave = state.temporaryComment!.copyWith(
      text: text.trim(),
      canvasId: canvasId,
    );

    await repository.add([commentToSave]);

    clearTemporaryComment();
  }

  void clearTemporaryComment() {
    state = state.copyWith(temporaryComment: null, objectId: null);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
