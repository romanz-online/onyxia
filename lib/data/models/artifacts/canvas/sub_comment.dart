import 'package:onyxia/services/timestamp_service.dart';

class SubComment {
  final String id;
  final String content;
  //
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  SubComment({
    required this.id,
    required this.content,
    //
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  SubComment copyWith({String? id, String? content}) {
    return SubComment(id: id ?? this.id, content: content ?? this.content);
  }

  /// Top-level Postgres columns. Repository injects `comment_id` at write time.
  Map<String, dynamic> toMap() {
    return {'id': id, 'content': content};
  }

  SubComment.fromMap(Map<String, dynamic> map)
      : id = map['id'] ?? '',
        content = map['content'] ?? '',
        //
        createdAt = TimestampService.fromMap(map['created_at']),
        createdBy = map['created_by'] ?? '',
        updatedAt = TimestampService.fromMap(map['updated_at']),
        updatedBy = map['updated_by'] ?? '';

  String timeAgo() => TimestampService.formatTimeAgo(createdAt);

  @override
  String toString() {
    return 'SubComment(id: $id, '
        'text: $content, '
        ')';
  }
}
