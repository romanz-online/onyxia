class HistoryDiff {
  final String userId;
  final String title;

  /// Timestamp doubles as ID.
  final DateTime timestamp;
  final List<Map<String, dynamic>> operations;
  final bool isMilestone;
  final bool isRestored;

  const HistoryDiff({
    required this.userId,
    this.title = '',
    required this.timestamp,
    required this.operations,
    required this.isMilestone,
    required this.isRestored,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'title': title,
        'timestamp': timestamp.toIso8601String(),
        'operations': operations,
        'isMilestone': isMilestone,
        'isRestored': isRestored,
      };

  factory HistoryDiff.fromJson(Map<String, dynamic> json) => HistoryDiff(
        userId: json['userId'],
        title: json['title'],
        timestamp: DateTime.parse(json['timestamp']),
        operations: List<Map<String, dynamic>>.from(json['operations'] ?? []),
        isMilestone: json['isMilestone'] ?? false,
        isRestored: json['isRestored'] ?? false,
      );

  HistoryDiff copyWith({
    String? userId,
    String? title,
    DateTime? timestamp,
    List<Map<String, dynamic>>? operations,
    bool? isMilestone,
    bool? isRestored,
  }) {
    return HistoryDiff(
      userId: userId ?? this.userId,
      title: title ?? this.title,
      timestamp: timestamp ?? this.timestamp,
      operations: operations ?? this.operations,
      isMilestone: isMilestone ?? this.isMilestone,
      isRestored: isRestored ?? this.isRestored,
    );
  }

  @override
  String toString() {
    return 'CanvasChangeDiff(userId: $userId, '
        'title: $title, '
        'timestamp: $timestamp, '
        'isMilestone: $isMilestone, '
        'isRestored: $isRestored, '
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HistoryDiff && other.timestamp == timestamp && other.userId == userId;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        title.hashCode ^
        timestamp.hashCode ^
        operations.hashCode ^
        isMilestone.hashCode ^
        isRestored.hashCode;
  }
}
