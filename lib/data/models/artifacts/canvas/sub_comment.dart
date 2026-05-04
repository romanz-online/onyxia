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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'authorId': authorId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory SubComment.fromMap(Map<String, dynamic> map) {
    return SubComment(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      authorId: map['authorId'] ?? '',
      createdAt: map['createdAt'] != null ? _parseDateTime(map['createdAt']) : null,
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
