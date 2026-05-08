import 'package:onyxia/export.dart';

class HistoryDiffsRepository extends BaseSupabaseRepository<HistoryDiff> {
  final String? itemId;
  final ArtifactType? itemType;

  /// Item-specific (canvas) history operations.
  HistoryDiffsRepository({
    required super.projectId,
    required this.itemId,
    required this.itemType,
  });

  /// Project-wide constructor; only generic CRUD is available — item-specific
  /// methods throw on this instance.
  HistoryDiffsRepository.forProject({required super.projectId})
      : itemId = null,
        itemType = null;

  @override
  String get tableName => 'history_diffs';

  @override
  String? get scopeField => itemId != null ? 'canvas_artifact_id' : null;

  @override
  dynamic get scopeValue => itemId;

  @override
  String get defaultOrderBy => 'seq';

  @override
  HistoryDiff fromMap(Map<String, dynamic> map) => HistoryDiff.fromMap(map);

  @override
  Map<String, dynamic> toMap(HistoryDiff item) => item.toMap();

  @override
  String getIdFromItem(HistoryDiff item) => item.id;

  void _requireItem(String op) {
    if (itemId == null || itemType == null) {
      throw ArgumentError('$op requires itemId and itemType. Use the item-specific constructor.');
    }
  }

  Future<void> addHistoryDiff(HistoryDiff diff) async {
    _requireItem('addHistoryDiff()');
    return add([diff]);
  }

  Future<void> deleteHistoryDiff(HistoryDiff diff) async {
    _requireItem('deleteHistoryDiff()');
    return delete(diff);
  }

  /// Re-insert a previously deleted diff. With server-assigned `seq`, the diff
  /// gets a fresh sequence number on insertion.
  Future<void> restoreHistoryDiff(HistoryDiff diff) async {
    _requireItem('restoreHistoryDiff()');
    return add([diff]);
  }

  Future<void> updateHistoryDiff(HistoryDiff diff) async {
    _requireItem('updateHistoryDiff()');
    return update(diff);
  }

  Stream<List<HistoryDiff>> getHistoryDiffsStream() {
    _requireItem('getHistoryDiffsStream()');
    return getStream();
  }
}
