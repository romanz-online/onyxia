import 'package:onyxia/export.dart';

class Comments {
  final List<Comment> comments;
  final Comment selectedComment;
  Comments({
    required this.comments,
    required this.selectedComment,
  });

  factory Comments.initial() {
    return Comments(
      comments: [],
      selectedComment: Comment.initial(), // Domyślnie wybrany obiekt
    );
  }

  Comments copyWith({
    List<Comment>? comments,
    Comment? selectedComment,
  }) {
    return Comments(
      comments: comments ?? this.comments,
      selectedComment: selectedComment ?? this.selectedComment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'comments': comments.map((x) => x.toMap()).toList(),
      'selectedComment': selectedComment.toMap(),
    };
  }

  factory Comments.fromMap(Map<String, dynamic> map) {
    return Comments(
      comments:
          List<Comment>.from(map['comments']?.map((x) => Comment.fromMap(x))),
      selectedComment: Comment.fromMap(map['selectedComment']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Comments.fromJson(String source) =>
      Comments.fromMap(json.decode(source));

  @override
  String toString() =>
      'Comments(comments: $comments, selectedComment: $selectedComment)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Comments &&
        listEquals(other.comments, comments) &&
        other.selectedComment == selectedComment;
  }

  @override
  int get hashCode => comments.hashCode ^ selectedComment.hashCode;
}
