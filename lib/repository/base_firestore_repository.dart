import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onyxia/export.dart';

abstract class BaseFirestoreRepository<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String projectId;

  /// Prevents echo updates
  bool isLocalUpdate = false;

  BaseFirestoreRepository({required this.projectId});

  /// Abstract methods that each repository must implement
  String get collectionPath;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  String getIdFromItem(T item);

  /// Whether this repository should update project metadata on execute()
  /// Override in subclasses to control project timestamp updates
  bool get updateProjectMetadata => true;

  /// Get current user ID from Firebase Auth
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Inject updatedAt and updatedBy fields into document data
  Map<String, dynamic> _blame(Map<String, dynamic> data) {
    final auditData = Map<String, dynamic>.from(data);

    // Always add updatedAt with milliseconds since epoch for DateTime compatibility
    auditData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

    // Add updatedBy if user is authenticated
    final userId = _currentUserId;
    if (userId != null) {
      auditData['updatedBy'] = userId;
    }

    return auditData;
  }

  /// Inject createdAt and createdBy fields into document data for new documents
  Map<String, dynamic> _create(Map<String, dynamic> data) {
    final auditData = Map<String, dynamic>.from(data);

    // Always add createdAt with milliseconds since epoch for DateTime compatibility
    auditData['createdAt'] = DateTime.now().millisecondsSinceEpoch;

    // Add createdBy if user is authenticated
    final userId = _currentUserId;
    if (userId != null) {
      auditData['createdBy'] = userId;
    }

    return auditData;
  }

  /// Execute write operations with projectId validation and project timestamp update.
  ///
  /// [suppressStream] controls whether [isLocalUpdate] is set during the operation.
  /// Set to false when the tree notifier should receive the Firestore echo (e.g.
  /// editor saves), true when the caller has already applied an optimistic local
  /// update and the echo would be redundant or cause flickering.
  Future<R> execute<R>(Future<R> Function() operation, {bool suppressStream = true}) async {
    if (projectId.isEmpty) throw ArgumentError('Invalid projectId: $projectId');

    isLocalUpdate = suppressStream;
    try {
      final result = await operation();

      // Only update project metadata if this repository requires it
      if (updateProjectMetadata) {
        await _firestore.collection('projects').doc(projectId).update({
          'updatedAt': DateTime.now(),
        });
      }
      return result;
    } finally {
      isLocalUpdate = false;
    }
  }

  /// Execute read-only operations with projectId validation but without updating project timestamp
  Future<R> executeRead<R>(Future<R> Function() operation) async {
    if (projectId.isEmpty) throw ArgumentError('Empty projectId');

    return await operation();
  }

  /// Execute stream operations with projectId validation
  Stream<R> executeStream<R>(Stream<R> Function() streamOperation, R emptyValue) {
    if (projectId.isEmpty) {
      debugPrint('Repository: Returning empty stream for invalid projectId: $projectId');
      return Stream.value(emptyValue);
    }

    return streamOperation();
  }

  /// Uniform CRUD operations - same across all repositories

  /// Get a single document by ID
  Future<T?> get(String id) {
    return executeRead(() async {
      final doc = await _firestore.doc('$collectionPath/$id').get();
      return doc.exists ? fromMap(doc.data()!) : null;
    });
  }

  /// Add a document with specific ID
  Future<void> add(T item, {bool suppressStream = true}) {
    return execute(() {
      final data = _create(toMap(item));
      final docPath = '$collectionPath/${getIdFromItem(item)}';
      return _firestore.doc(docPath).set(data);
    }, suppressStream: suppressStream);
  }

  /// Update a document by ID.
  ///
  /// Pass [suppressStream] false when the caller wants the Firestore echo to
  /// flow through to stream listeners (e.g. editor saves that the tree hasn't
  /// applied optimistically). Defaults to true so tree operations that have
  /// already updated local state don't receive a redundant echo.
  Future<void> update(T item, {bool suppressStream = true}) {
    return execute(() {
      final data = _blame(toMap(item));
      return _firestore.doc('$collectionPath/${getIdFromItem(item)}').update(data);
    }, suppressStream: suppressStream);
  }

  /// Update multiple documents at once
  Future<void> updateMultiple(List<T> items, {bool suppressStream = true}) {
    if (items.length == 1) {
      return update(items.first, suppressStream: suppressStream);
    } else {
      return execute(() async {
        final batch = _firestore.batch();
        items.forEach((item) => batch.update(
              _firestore.doc('$collectionPath/${getIdFromItem(item)}'),
              _blame(toMap(item)),
            ));
        await batch.commit();
      }, suppressStream: suppressStream);
    }
  }

  /// Delete a document by ID or item
  Future<void> delete(dynamic item) {
    final String id;
    if (item is String) {
      id = item;
    } else if (item is T) {
      id = getIdFromItem(item);
    } else {
      throw ArgumentError('Invalid parameter: $item');
    }
    return execute(() => _firestore.doc('$collectionPath/$id').delete());
  }

  /// Delete multiple documents by ID or item
  Future<void> deleteMultiple(List<dynamic> items) {
    return execute(() async {
      final batch = _firestore.batch();
      for (final item in items) {
        final String id;
        if (item is String) {
          id = item;
        } else if (item is T) {
          id = getIdFromItem(item);
        } else {
          throw ArgumentError('Invalid List parameter: $item');
        }

        batch.delete(_firestore.doc('$collectionPath/$id'));
      }
      await batch.commit();
    });
  }

  /// Get stream of all documents in collection
  Stream<List<T>> getStream({Query? query}) {
    return executeStream(() {
      final baseQuery = query ?? _firestore.collection(collectionPath);
      return baseQuery
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => fromMap(doc.data() as Map<String, dynamic>)).toList());
    }, <T>[]);
  }

  /// Get stream of a single document by ID
  Stream<T?> getDocumentStream(String id) {
    return executeStream(() {
      return _firestore
          .doc('$collectionPath/$id')
          .snapshots()
          .map((snapshot) => snapshot.exists ? fromMap(snapshot.data()!) : null);
    }, null);
  }

  /// Add multiple documents at once
  Future<void> addMultiple(Map<String, T> items, {bool suppressStream = true}) {
    return execute(() async {
      final batch = _firestore.batch();
      for (final entry in items.entries) {
        final data = _create(toMap(entry.value));
        batch.set(_firestore.doc('$collectionPath/${entry.key}'), data);
      }
      await batch.commit();
    }, suppressStream: suppressStream);
  }

  /// Get all documents as a list (for one-time reads)
  Future<List<T>> getAll() {
    return executeRead(() async {
      final snapshot = await _firestore.collection(collectionPath).get();
      return snapshot.docs.map((doc) => fromMap(doc.data())).toList();
    });
  }

  /// Query documents with custom where clauses
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
    return executeRead(() async {
      Query query = _firestore.collection(collectionPath);

      if (field != null) {
        if (isEqualTo != null) query = query.where(field, isEqualTo: isEqualTo);
        if (isNotEqualTo != null) query = query.where(field, isNotEqualTo: isNotEqualTo);
        if (isLessThan != null) query = query.where(field, isLessThan: isLessThan);
        if (isLessThanOrEqualTo != null) query = query.where(field, isLessThanOrEqualTo: isLessThanOrEqualTo);
        if (isGreaterThan != null) query = query.where(field, isGreaterThan: isGreaterThan);
        if (isGreaterThanOrEqualTo != null) query = query.where(field, isGreaterThanOrEqualTo: isGreaterThanOrEqualTo);
        if (arrayContains != null) query = query.where(field, arrayContains: arrayContains);
        if (arrayContainsAny != null) query = query.where(field, arrayContainsAny: arrayContainsAny);
        if (whereIn != null) query = query.where(field, whereIn: whereIn);
        if (whereNotIn != null) query = query.where(field, whereNotIn: whereNotIn);
        if (isNull != null) query = query.where(field, isNull: isNull);
      }

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  /// Query documents with custom where clauses as a stream
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
    return executeStream(() {
      Query query = _firestore.collection(collectionPath);

      if (field != null) {
        if (isEqualTo != null) query = query.where(field, isEqualTo: isEqualTo);
        if (isNotEqualTo != null) query = query.where(field, isNotEqualTo: isNotEqualTo);
        if (isLessThan != null) query = query.where(field, isLessThan: isLessThan);
        if (isLessThanOrEqualTo != null) query = query.where(field, isLessThanOrEqualTo: isLessThanOrEqualTo);
        if (isGreaterThan != null) query = query.where(field, isGreaterThan: isGreaterThan);
        if (isGreaterThanOrEqualTo != null) query = query.where(field, isGreaterThanOrEqualTo: isGreaterThanOrEqualTo);
        if (arrayContains != null) query = query.where(field, arrayContains: arrayContains);
        if (arrayContainsAny != null) query = query.where(field, arrayContainsAny: arrayContainsAny);
        if (whereIn != null) query = query.where(field, whereIn: whereIn);
        if (whereNotIn != null) query = query.where(field, whereNotIn: whereNotIn);
        if (isNull != null) query = query.where(field, isNull: isNull);
      }

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return query
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => fromMap(doc.data() as Map<String, dynamic>)).toList());
    }, <T>[]);
  }

  /// Delete all documents matching query criteria
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
  }) {
    return execute(() async {
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
    });
  }
}
