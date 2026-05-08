import 'package:onyxia/services/timestamp_service.dart';

class SubComment {
  final String id;
  final String text;
  final String authorId;
  final DateTime? createdAt;

  SubComment({
    required this.id,
    required this.text,
    required this.authorId,
    this.createdAt,
  });

  SubComment copyWith({
    String? id,
    String? text,
    String? authorId,
    DateTime? createdAt,
  }) {
    return SubComment(
      id: id ?? this.id,
      text: text ?? this.text,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Top-level Postgres columns. Repository injects `comment_id` at write time.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author_id': authorId,
      'body': text,
    };
  }

  factory SubComment.fromMap(Map<String, dynamic> map) {
    return SubComment(
      id: map['id'] ?? '',
      text: map['body'] ?? '',
      authorId: map['author_id'] ?? '',
      createdAt: map['created_at'] != null ? _parseDateTime(map['created_at']) : null,
    );
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

  String timeAgo() {
    return createdAt != null ? TimestampService.formatTimeAgo(createdAt!) : '';
  }

  @override
  String toString() {
    return 'SubComment(id: $id, text: $text, authorId: $authorId, createdAt: $createdAt)';
  }
}
