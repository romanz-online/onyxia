import 'package:onyxia/export.dart';

class HistoryDiff {
  final String id;
  final int seq;
  final String createdBy;
  final String title;
  final DateTime timestamp;
  final List<Map<String, dynamic>> operations;
  final bool isMilestone;
  final bool isRestored;

  const HistoryDiff({
    this.id = '',
    this.seq = 0,
    required this.createdBy,
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
          'created_by': createdBy,
          'title': title,
          'operations': operations,
          'is_milestone': isMilestone,
          'is_restored': isRestored,
        },
      };

  factory HistoryDiff.fromMap(Map<String, dynamic> map) {
    final diff =
        (map['diff'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    DateTime ts = DateTime.now();
    final raw = map['created_at'];
    if (raw is String) ts = DateTime.tryParse(raw) ?? DateTime.now();
    if (raw is int) ts = DateTime.fromMillisecondsSinceEpoch(raw);
    return HistoryDiff(
      id: map['id'] ?? '',
      seq: (map['seq'] as num?)?.toInt() ?? 0,
      createdBy: diff['created_by'] ?? '',
      title: diff['title'] ?? '',
      timestamp: ts,
      operations: List<Map<String, dynamic>>.from(diff['operations'] ?? []),
      isMilestone: diff['is_milestone'] ?? false,
      isRestored: diff['is_restored'] ?? false,
    );
  }

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
      createdBy: userId ?? this.createdBy,
      title: title ?? this.title,
      timestamp: timestamp ?? this.timestamp,
      operations: operations ?? this.operations,
      isMilestone: isMilestone ?? this.isMilestone,
      isRestored: isRestored ?? this.isRestored,
    );
  }

  @override
  String toString() {
    return 'HistoryDiff(userId: $createdBy, '
        'title: $title, '
        'timestamp: $timestamp, '
        'isMilestone: $isMilestone, '
        'isRestored: $isRestored, '
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HistoryDiff &&
        other.timestamp == timestamp &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode {
    return createdBy.hashCode ^
        title.hashCode ^
        timestamp.hashCode ^
        operations.hashCode ^
        isMilestone.hashCode ^
        isRestored.hashCode;
  }
}

class HistoryDiffs {
  final HistoryDiff? selectedDiff;
  final HistoryDiff? currentDiff;
  final List<HistoryDiff> remoteDiffs;
  final List<HistoryDiff> localDiffs;
  final DateTime? createdAt;

  HistoryDiffs({
    this.selectedDiff,
    this.currentDiff,
    required this.remoteDiffs,
    required this.localDiffs,
    this.createdAt,
  });

  factory HistoryDiffs.initial() => HistoryDiffs(
        remoteDiffs: [],
        localDiffs: [],
      );

  HistoryDiffs copyWith({
    HistoryDiff? selectedDiff,
    HistoryDiff? currentDiff,
    List<HistoryDiff>? remoteDiffs,
    List<HistoryDiff>? localDiffs,
    DateTime? createdAt,
  }) {
    return HistoryDiffs(
      selectedDiff: selectedDiff ?? this.selectedDiff,
      currentDiff: currentDiff ?? this.currentDiff,
      remoteDiffs: remoteDiffs ?? this.remoteDiffs,
      localDiffs: localDiffs ?? this.localDiffs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HistoryDiffs &&
        listEquals(other.remoteDiffs, remoteDiffs) &&
        listEquals(other.localDiffs, localDiffs) &&
        other.currentDiff == currentDiff &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      remoteDiffs.hashCode ^
      localDiffs.hashCode ^
      currentDiff.hashCode ^
      createdAt.hashCode;
}
