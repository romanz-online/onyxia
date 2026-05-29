import 'package:onyxia/export.dart';

abstract class BaseSupabaseRepository<T> {
  final String? vaultId;

  BaseSupabaseRepository({this.vaultId});

  /// Abstract methods each repository must implement.
  String get tableName;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  String getIdFromItem(T item);

  /// Override to false in repositories that are not vault-scoped (e.g. `users`).
  bool get requireVaultId => true;

  /// Column used to scope reads and writes. When set, `getAll`/`getStream`
  /// auto-filter by `scopeField = scopeValue`, and `add`/`update` auto-inject
  /// the column into the row map. Leave null for non-scoped tables.
  String? get scopeField => null;

  /// Value paired with `scopeField`. Defaults to `vaultId`; override when
  /// scoping by a different column (e.g. `canvasId`, `itemId`).
  dynamic get scopeValue => vaultId;

  /// Default `orderBy` applied to `getStream` when the caller doesn't pass one.
  String? get defaultOrderBy => null;

  /// Primary-key column(s). Override for composite-key tables (e.g.
  /// `vault_members` keyed on `(vault_id, user_id)`). Used by realtime
  /// `.stream()` setup.
  List<String> get primaryKeyFields => const ['id'];

  /// Equality filter used for update/delete. Override for composite-key tables
  /// to return all key columns. Default keys off the single `id` column.
  Map<String, dynamic> keyFilter(T item) => {'id': getIdFromItem(item)};

  SupabaseClient get _client => Supabase.instance.client;
  SupabaseQueryBuilder get _table => _client.from(tableName);

  /// Builds the row map for inserts/updates: `toMap(item)` + scope column
  /// auto-injected. Only injects when both `scopeField` and `scopeValue` are
  /// non-null.
  Map<String, dynamic> _writeMap(T item) {
    final map = toMap(item);
    final field = scopeField;
    final value = scopeValue;
    if (field != null && value != null) map[field] = value;
    return map;
  }

  Future<R> _execute<R>(Future<R> Function() op) async {
    if (requireVaultId && (vaultId == null || vaultId!.isEmpty)) {
      throw ArgumentError('Invalid vaultId: $vaultId');
    }

    return await op();
  }

  Stream<R> _executeStream<R>(Stream<R> Function() op, R emptyValue) {
    if (requireVaultId && (vaultId == null || vaultId!.isEmpty)) {
      return Stream.value(emptyValue);
    }
    return op();
  }

  // ------------- CRUD -------------

  Future<T?> get(String id) {
    return _execute(() async {
      final row = await _table.select().eq('id', id).maybeSingle();
      return row == null ? null : fromMap(row);
    });
  }

  Future<List<T>> getAll() => query(field: scopeField, isEqualTo: scopeValue);

  Future<List<T>> add(List<T> items) {
    return _execute(() async {
      if (items.isEmpty) return <T>[];
      final rows = await _table.insert(items.map(_writeMap).toList()).select();
      return (rows as List)
          .map((r) => fromMap(r as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> update(List<T> items) {
    if (items.length == 1) {
      return _execute(() async {
        dynamic q = _table.update(_writeMap(items.first));
        keyFilter(items.first).forEach((k, v) => q = q.eq(k, v));
        await q;
      });
    }
    return _execute(() async {
      if (items.isEmpty) return;
      await Future.wait(
        items.map((item) {
          dynamic q = _table.update(_writeMap(item));
          keyFilter(item).forEach((k, v) => q = q.eq(k, v));
          return q;
        }),
      );
    });
  }

  Future<void> delete(dynamic item) {
    final Map<String, dynamic> filter;
    if (item is String) {
      filter = {'id': item};
    } else if (item is T) {
      filter = keyFilter(item);
    } else {
      throw ArgumentError('Invalid parameter: $item');
    }
    return _execute(() async {
      dynamic q = _table.delete();
      filter.forEach((k, v) => q = q.eq(k, v));
      await q;
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
    String? startsWith,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    return _execute(() async {
      dynamic q = _table.select();
      if (field != null) {
        if (isEqualTo != null) q = q.eq(field, isEqualTo);
        if (isNotEqualTo != null) q = q.neq(field, isNotEqualTo);
        if (isLessThan != null) q = q.lt(field, isLessThan);
        if (isLessThanOrEqualTo != null) q = q.lte(field, isLessThanOrEqualTo);
        if (isGreaterThan != null) q = q.gt(field, isGreaterThan);
        if (isGreaterThanOrEqualTo != null)
          q = q.gte(field, isGreaterThanOrEqualTo);
        if (arrayContains != null) q = q.contains(field, [arrayContains]);
        if (arrayContainsAny != null) q = q.overlaps(field, arrayContainsAny);
        if (whereIn != null) q = q.inFilter(field, whereIn);
        if (whereNotIn != null) q = q.not(field, 'in', whereNotIn);
        if (isNull != null) {
          q = isNull ? q.isFilter(field, null) : q.not(field, 'is', null);
        }
        if (startsWith != null) q = q.like(field, '$startsWith%');
      }
      if (orderBy != null) q = q.order(orderBy, ascending: !descending);
      if (limit != null) q = q.limit(limit);
      final rows = await q;
      return (rows as List)
          .map((r) => fromMap(r as Map<String, dynamic>))
          .toList();
    });
  }

  // ------------- Streams (Realtime) -------------

  Stream<List<T>> getStream({String? orderBy, bool descending = false}) {
    return queryStream(
      field: scopeField,
      isEqualTo: scopeValue,
      orderBy: orderBy ?? defaultOrderBy,
      descending: descending,
    );
  }

  Stream<T?> getDocumentStream(String id) {
    return _executeStream<T?>(() {
      return _table
          .stream(primaryKey: primaryKeyFields)
          .eq('id', id)
          .map((rows) => rows.isEmpty ? null : fromMap(rows.first));
    }, null);
  }

  /// Streamed query. Realtime supports only a single server-side `.eq()` filter
  /// plus `order` and `limit` — for anything richer use a one-shot `query()`.
  Stream<List<T>> queryStream({
    String? field,
    dynamic isEqualTo,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    return _executeStream<List<T>>(() {
      final filter = _table.stream(primaryKey: primaryKeyFields);
      SupabaseStreamBuilder stream = (field != null && isEqualTo != null)
          ? filter.eq(field, isEqualTo)
          : filter;
      if (orderBy != null)
        stream = stream.order(orderBy, ascending: !descending);
      if (limit != null) stream = stream.limit(limit);
      return stream.map((rows) => rows.map((r) => fromMap(r)).toList());
    }, <T>[]);
  }
}
