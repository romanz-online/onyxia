class HistoryDiff {
  final String id;
  final int seq;
  final String userId;
  final String title;
  final DateTime timestamp;
  final List<Map<String, dynamic>> operations;
  final bool isMilestone;
  final bool isRestored;

  const HistoryDiff({
    this.id = '',
    this.seq = 0,
    required this.userId,
    this.title = '',
    required this.timestamp,
    required this.operations,
    required this.isMilestone,
    required this.isRestored,
  });

  /// Top-level Postgres columns. Repository injects `canvas_artifact_id`;
  /// `seq` is assigned by the Phase B trigger.
  Map<String, dynamic> toMap() => {
        if (id.isNotEmpty) 'id': id,
        'diff': {
          'userId': userId,
          'title': title,
          'operations': operations,
          'isMilestone': isMilestone,
          'isRestored': isRestored,
        },
      };

  factory HistoryDiff.fromMap(Map<String, dynamic> map) {
    final diff = (map['diff'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    DateTime ts = DateTime.now();
    final raw = map['created_at'];
    if (raw is String) ts = DateTime.tryParse(raw) ?? DateTime.now();
    if (raw is int) ts = DateTime.fromMillisecondsSinceEpoch(raw);
    return HistoryDiff(
      id: map['id'] ?? '',
      seq: (map['seq'] as num?)?.toInt() ?? 0,
      userId: diff['userId'] ?? '',
      title: diff['title'] ?? '',
      timestamp: ts,
      operations: List<Map<String, dynamic>>.from(diff['operations'] ?? []),
      isMilestone: diff['isMilestone'] ?? false,
      isRestored: diff['isRestored'] ?? false,
    );
  }

  /// Backwards-compat alias used by existing serializers.
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
    String? id,
    int? seq,
    String? userId,
    String? title,
    DateTime? timestamp,
    List<Map<String, dynamic>>? operations,
    bool? isMilestone,
    bool? isRestored,
  }) {
    return HistoryDiff(
      id: id ?? this.id,
      seq: seq ?? this.seq,
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
