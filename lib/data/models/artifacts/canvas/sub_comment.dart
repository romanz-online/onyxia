import 'package:onyxia/services/timestamp_service.dart';

class SubComment {
  final String id;
  final String content;
  final String createdBy;
  final DateTime? createdAt;

  SubComment({
    required this.id,
    required this.content,
    required this.createdBy,
    this.createdAt,
  });

  SubComment copyWith({
    String? id,
    String? content,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return SubComment(
      id: id ?? this.id,
      content: content ?? this.content,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Top-level Postgres columns. Repository injects `comment_id` at write time.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_by': createdBy,
      'created_at': createdAt,
      'content': content,
    };
  }

  factory SubComment.fromMap(Map<String, dynamic> map) {
    return SubComment(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      createdBy: map['created_by'] ?? '',
      createdAt: TimestampService.fromMap(map['created_at']),
    );
  }

  String timeAgo() => TimestampService.formatTimeAgo(createdAt);

  @override
  String toString() {
    return 'SubComment(id: $id, '
        'text: $content, '
        'createdBy: $createdBy, '
        'createdAt: $createdAt, '
        ')';
  }
}
