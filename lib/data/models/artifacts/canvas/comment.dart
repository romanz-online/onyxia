import 'package:onyxia/export.dart';

class Comment implements ExpandablePin {
  @override
  final String id;
  final String text;
  @override
  final Offset? position;
  final Color color;
  final List<SubComment> subComments;
  final String authorId;
  final DateTime? createdAt;
  final String? pinnedObjectId;
  final String? targetId;
  final bool resolved;
  final CommentTargetType? targetType;

  Comment({
    required this.id,
    required this.text,
    this.position,
    required this.color,
    required this.subComments,
    required this.authorId,
    this.createdAt,
    this.pinnedObjectId,
    this.targetId,
    this.resolved = false,
    this.targetType,
  });

  factory Comment.initial() => Comment(
        id: '',
        color: Colors.transparent,
        text: '',
        authorId: '',
        subComments: [],
        pinnedObjectId: null,
        resolved: false,
      );

  static final empty = Comment(
    id: '',
    color: Colors.transparent,
    text: '',
    authorId: '',
    subComments: [],
    pinnedObjectId: null,
    resolved: false,
  );

  Comment copyWith({
    String? id,
    String? text,
    Offset? position,
    Color? color,
    List<SubComment>? subComments,
    String? authorId,
    DateTime? createdAt,
    String? pinnedObjectId,
    String? targetId,
    bool? resolved,
    CommentTargetType? targetType,
  }) {
    return Comment(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      subComments: subComments ?? this.subComments,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      pinnedObjectId: pinnedObjectId ?? this.pinnedObjectId,
      targetId: targetId ?? this.targetId,
      resolved: resolved ?? this.resolved,
      targetType: targetType ?? this.targetType,
    );
  }

  /// Top-level Postgres columns. `subComments` are stored in a separate table
  /// and populated lazily by the comments repository — never serialized here.
  Map<String, dynamic> toMap() => {
        'id': id,
        'target_id': targetId,
        'target_type': (targetType ?? CommentTargetType.canvas).name,
        'author_id': authorId,
        'body': text,
        'x': position?.dx,
        'y': position?.dy,
        'color': color.toARGB32(),
        'pinned_object_id': pinnedObjectId,
        'resolved': resolved,
      };

  factory Comment.fromMap(Map<String, dynamic> map) {
    try {
      final dx = (map['x'] as num?)?.toDouble();
      final dy = (map['y'] as num?)?.toDouble();
      return Comment(
        id: map['id']?.toString() ?? '',
        text: map['body']?.toString() ?? '',
        position: (dx != null && dy != null) ? Offset(dx, dy) : null,
        color: Color(map['color'] ?? 0),
        subComments: const [],
        authorId: map['author_id']?.toString() ?? '',
        createdAt: map['created_at'] != null ? _parseDateTime(map['created_at']) : null,
        pinnedObjectId: map['pinned_object_id']?.toString(),
        targetId: map['target_id']?.toString(),
        resolved: map['resolved'] ?? false,
        targetType: CommentTargetType.fromString(map['target_type']?.toString()),
      );
    } catch (e) {
      debugPrint('Error in Comment.fromMap with data: $map');
      debugPrint('Error details: $e');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is num) {
      // Handle timestamp (milliseconds since epoch)
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    } else if (value is String) {
      // Handle ISO string format
      return DateTime.parse(value);
    } else {
      throw ArgumentError('Invalid DateTime format: $value');
    }
  }

  String toJson() => json.encode(toMap());

  factory Comment.fromJson(String source) => Comment.fromMap(json.decode(source));

  /// Calculate the actual position of the comment on the canvas.
  /// If parent is null, uses absolute positioning.
  /// If parent is provided, uses relative positioning as a percentage of the parent object.
  @override
  Offset getOffset({CanvasObject? parent}) {
    if (position == null) return Offset.zero;

    if (parent == null) {
      return position!;
    } else if (parent.isArrow) {
      // Arrow positioning: position.dx is percentage along arrow path (0.0-1.0)
      final arrowPoints = parent.arrowProps.points;
      return ArrowPathHelper.getPointAtPercentage(arrowPoints, position!.dx);
    } else {
      // Regular object positioning: relative positioning based on dimensions
      final objSize = parent.getDimensions();
      return parent.topLeft +
          Offset(
            position!.dx * objSize.width,
            position!.dy * objSize.height,
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
      'color: $color, '
      'subComments: $subComments, '
      'authorId: $authorId, '
      'createdAt: $createdAt, '
      'pinnedObjectId: $pinnedObjectId, '
      'resolved: $resolved, '
      ')';
}

/// Type of target for a comment
enum CommentTargetType {
  canvas,
  note;

  /// Parse from string, returns canvas as default for backward compatibility
  static CommentTargetType fromString(String? value) {
    if (value == null) return CommentTargetType.canvas;

    switch (value.toLowerCase()) {
      case 'canvas':
        return CommentTargetType.canvas;
      case 'note':
        return CommentTargetType.note;
      default:
        return CommentTargetType.canvas;
    }
  }
}
