import 'package:onyxia/export.dart';

abstract class BaseSupabaseRepository<T> {
  final String? projectId;

  /// Echo-suppression flag preserved from the Firestore-era base. Consumers that
  /// listen to repository streams may read this to ignore echoes from their own
  /// optimistic updates.
  bool isLocalUpdate = false;

  BaseSupabaseRepository({this.projectId});

  /// Abstract methods each repository must implement.
  String get tableName;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  String getIdFromItem(T item);

  /// Override to false in repositories that are not project-scoped (e.g. `users`).
  bool get requireProjectId => true;

  SupabaseClient get _client => Supabase.instance.client;
  SupabaseQueryBuilder get _table => _client.from(tableName);

  Future<R> _execute<R>(Future<R> Function() op, {bool suppressStream = true}) async {
    if (requireProjectId && (projectId == null || projectId!.isEmpty)) {
      throw ArgumentError('Invalid projectId: $projectId');
    }
    isLocalUpdate = suppressStream;
    try {
      return await op();
    } finally {
      isLocalUpdate = false;
    }
  }

  Future<R> _executeRead<R>(Future<R> Function() op) async {
    if (requireProjectId && (projectId == null || projectId!.isEmpty)) {
      throw ArgumentError('Empty projectId');
    }
    return await op();
  }

  Stream<R> _executeStream<R>(Stream<R> Function() op, R emptyValue) {
    if (requireProjectId && (projectId == null || projectId!.isEmpty)) {
      return Stream.value(emptyValue);
    }
    return op();
  }

  // ------------- CRUD -------------

  Future<T?> get(String id) {
    return _executeRead(() async {
      final row = await _table.select().eq('id', id).maybeSingle();
      return row == null ? null : fromMap(row);
    });
  }

  Future<List<T>> getAll() {
    return _executeRead(() async {
      final rows = await _table.select();
      return (rows as List).map((r) => fromMap(r as Map<String, dynamic>)).toList();
    });
  }

  Future<void> add(T item, {bool suppressStream = true}) {
    return _execute(() async {
      await _table.insert(toMap(item));
    }, suppressStream: suppressStream);
  }

  Future<void> addMultiple(Map<String, T> items, {bool suppressStream = true}) {
    return _execute(() async {
      if (items.isEmpty) return;
      await _table.insert(items.values.map(toMap).toList());
    }, suppressStream: suppressStream);
  }

  Future<void> update(T item, {bool suppressStream = true}) {
    return _execute(() async {
      await _table.update(toMap(item)).eq('id', getIdFromItem(item));
    }, suppressStream: suppressStream);
  }

  Future<void> updateMultiple(List<T> items, {bool suppressStream = true}) {
    if (items.length == 1) {
      return update(items.first, suppressStream: suppressStream);
    }
    return _execute(() async {
      if (items.isEmpty) return;
      await _table.upsert(items.map(toMap).toList());
    }, suppressStream: suppressStream);
  }

  Future<void> delete(dynamic item) {
    final String id;
    if (item is String) {
      id = item;
    } else if (item is T) {
      id = getIdFromItem(item);
    } else {
      throw ArgumentError('Invalid parameter: $item');
    }
    return _execute(() async {
      await _table.delete().eq('id', id);
    });
  }

  Future<void> deleteMultiple(List<dynamic> items) {
    return _execute(() async {
      if (items.isEmpty) return;
      final ids = items.map((item) {
        if (item is String) return item;
        if (item is T) return getIdFromItem(item);
        throw ArgumentError('Invalid List parameter: $item');
      }).toList();
      await _table.delete().inFilter('id', ids);
    });
  }

  Future<void> deleteWhere({
    String? field,
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
    bool? isNull,
  }) async {
    final results = await query(
      field: field,
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      arrayContains: arrayContains,
      arrayContainsAny: arrayContainsAny,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
      isNull: isNull,
    );
    if (results.isNotEmpty) {
      await deleteMultiple(results);
    }
  }

  // ------------- Queries -------------

  Future<List<T>> query({
    String? field,
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
    bool? isNull,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    return _executeRead(() async {
      dynamic q = _table.select();
      if (field != null) {
        if (isEqualTo != null) q = q.eq(field, isEqualTo);
        if (isNotEqualTo != null) q = q.neq(field, isNotEqualTo);
        if (isLessThan != null) q = q.lt(field, isLessThan);
        if (isLessThanOrEqualTo != null) q = q.lte(field, isLessThanOrEqualTo);
        if (isGreaterThan != null) q = q.gt(field, isGreaterThan);
        if (isGreaterThanOrEqualTo != null) q = q.gte(field, isGreaterThanOrEqualTo);
        if (arrayContains != null) q = q.contains(field, [arrayContains]);
        if (arrayContainsAny != null) q = q.overlaps(field, arrayContainsAny);
        if (whereIn != null) q = q.inFilter(field, whereIn);
        if (whereNotIn != null) q = q.not(field, 'in', whereNotIn);
        if (isNull != null) {
          q = isNull ? q.isFilter(field, null) : q.not(field, 'is', null);
        }
      }
      if (orderBy != null) q = q.order(orderBy, ascending: !descending);
      if (limit != null) q = q.limit(limit);
      final rows = await q;
      return (rows as List).map((r) => fromMap(r as Map<String, dynamic>)).toList();
    });
  }

  // ------------- Streams (Realtime) -------------

  Stream<List<T>> getStream({String? orderBy, bool descending = false}) {
    return _executeStream<List<T>>(() {
      // .stream() returns SupabaseStreamFilterBuilder; .order() returns
      // SupabaseStreamBuilder, so the chain has to widen explicitly.
      SupabaseStreamBuilder stream = _table.stream(primaryKey: ['id']);
      if (orderBy != null) stream = stream.order(orderBy, ascending: !descending);
      return stream.map((rows) => rows.map((r) => fromMap(r)).toList());
    }, <T>[]);
  }

  Stream<T?> getDocumentStream(String id) {
    return _executeStream<T?>(() {
      return _table
          .stream(primaryKey: ['id'])
          .eq('id', id)
          .map((rows) => rows.isEmpty ? null : fromMap(rows.first));
    }, null);
  }

  /// Streamed query. Realtime supports only a single server-side `.eq()` filter
  /// — additional operators are applied client-side on each emitted snapshot.
  Stream<List<T>> queryStream({
    String? field,
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<dynamic>? arrayContainsAny,
    List<dynamic>? whereIn,
    List<dynamic>? whereNotIn,
    bool? isNull,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    return _executeStream<List<T>>(() {
      final filter = _table.stream(primaryKey: ['id']);
      // Realtime supports a single server-side .eq filter; anything else is
      // post-filtered client-side below.
      SupabaseStreamBuilder stream = (field != null && isEqualTo != null)
          ? filter.eq(field, isEqualTo)
          : filter;
      if (orderBy != null) stream = stream.order(orderBy, ascending: !descending);
      if (limit != null) stream = stream.limit(limit);

      return stream.map((rows) {
        Iterable<Map<String, dynamic>> filtered = rows;
        if (field != null) {
          if (isNotEqualTo != null) {
            filtered = filtered.where((r) => r[field] != isNotEqualTo);
          }
          if (isLessThan != null) {
            filtered = filtered.where((r) => (r[field] as Comparable).compareTo(isLessThan) < 0);
          }
          if (isLessThanOrEqualTo != null) {
            filtered = filtered.where((r) => (r[field] as Comparable).compareTo(isLessThanOrEqualTo) <= 0);
          }
          if (isGreaterThan != null) {
            filtered = filtered.where((r) => (r[field] as Comparable).compareTo(isGreaterThan) > 0);
          }
          if (isGreaterThanOrEqualTo != null) {
            filtered = filtered.where((r) => (r[field] as Comparable).compareTo(isGreaterThanOrEqualTo) >= 0);
          }
          if (whereIn != null) {
            filtered = filtered.where((r) => whereIn.contains(r[field]));
          }
          if (whereNotIn != null) {
            filtered = filtered.where((r) => !whereNotIn.contains(r[field]));
          }
          if (isNull != null) {
            filtered = filtered.where((r) => isNull ? r[field] == null : r[field] != null);
          }
        }
        return filtered.map((r) => fromMap(r)).toList();
      });
    }, <T>[]);
  }
}
