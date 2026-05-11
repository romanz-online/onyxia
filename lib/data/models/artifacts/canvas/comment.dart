import 'package:onyxia/export.dart';

class Comment implements ExpandablePin {
  @override
  final String id;
  final String text;
  @override
  final Offset position;
  final List<SubComment> subComments;
  final String? pinnedObjectId;
  final String? canvasId;
  //
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  Comment({
    required this.id,
    required this.text,
    this.position = Offset.zero,
    required this.subComments,
    this.pinnedObjectId,
    this.canvasId,
    //
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  Comment copyWith({
    String? id,
    String? text,
    Offset? position,
    List<SubComment>? subComments,
    String? pinnedObjectId,
    String? canvasId,
  }) {
    return Comment(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      subComments: subComments ?? this.subComments,
      pinnedObjectId: pinnedObjectId ?? this.pinnedObjectId,
      canvasId: canvasId ?? this.canvasId,
    );
  }

  /// Top-level Postgres columns. `subComments` are stored in a separate table
  /// and populated lazily by the comments repository — never serialized here.
  Map<String, dynamic> toMap() => {
        'id': id,
        'body': text,
        'position': position.toMap(),
        'pinned_object_id': pinnedObjectId,
        'canvas_artifact_id': canvasId,
      };

  Comment.fromMap(Map<String, dynamic> map)
      : id = map['id'] ?? '',
        text = map['body'] ?? '',
        position = OffsetExtension.fromMap(map['position']),
        subComments = const [],
        pinnedObjectId = map['pinned_object_id'] ?? '',
        canvasId = map['canvas_artifact_id'] ?? '',
        //
        createdAt = TimestampService.fromMap(map['created_at']),
        createdBy = map['created_by'] ?? '',
        updatedAt = TimestampService.fromMap(map['updated_at']),
        updatedBy = map['updated_by'] ?? '';

  /// Calculate the actual position of the comment on the canvas.
  /// If parent is null, uses absolute positioning.
  /// If parent is provided, uses relative positioning as a percentage of the parent object.
  @override
  Offset getOffset({CanvasObject? parent}) {
    if (parent == null) {
      return position;
    } else if (parent.isArrow) {
      // Arrow positioning: position.dx is percentage along arrow path (0.0-1.0)
      final arrowPoints = parent.arrowProps.points;
      return ArrowPathHelper.getPointAtPercentage(arrowPoints, position.dx);
    } else {
      // Regular object positioning: relative positioning based on dimensions
      final objSize = parent.getDimensions();
      return parent.topLeft +
          Offset(
            position.dx * objSize.width,
            position.dy * objSize.height,
          );
    }
  }

  String timeAgo() {
    return createdAt != null ? TimestampService.formatTimeAgo(createdAt!) : '';
  }

  @override
  String toString() => 'Comment('
      'id: $id, '
      'text: $text, '
      'position: $position, '
      'subComments: $subComments, '
      'pinnedObjectId: $pinnedObjectId, '
      'canvasId: $canvasId, '
      //
      'createdAt: $createdAt, '
      'createdBy: $createdBy, '
      'updatedAt: $updatedAt, '
      'updatedBy: $updatedBy, '
      ')';
}

class Comments {
  final List<Comment> comments;
  Comments({required this.comments});

  factory Comments.initial() => Comments(comments: []);

  Comments copyWith({List<Comment>? comments}) {
    return Comments(comments: comments ?? this.comments);
  }

  @override
  String toString() => 'Comments(comments: $comments)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Comments && listEquals(other.comments, comments);
  }

  @override
  int get hashCode => comments.hashCode;
}
