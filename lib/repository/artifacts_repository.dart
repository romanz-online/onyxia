import 'package:onyxia/export.dart';

class ArtifactsRepository extends BaseSupabaseRepository<Artifact> {
  ArtifactsRepository({required super.projectId});

  @override
  String get tableName => 'artifacts';

  @override
  Artifact fromMap(Map<String, dynamic> map) => Artifact.factory(map);

  @override
  Map<String, dynamic> toMap(Artifact item) => {
        ...item.toMap(),
        'project_id': projectId,
      };

  @override
  String getIdFromItem(Artifact item) => item.id;

  @override
  Future<List<Artifact>> getAll() => query(field: 'project_id', isEqualTo: projectId);

  @override
  Stream<List<Artifact>> getStream({String? orderBy, bool descending = false}) {
    return queryStream(
      field: 'project_id',
      isEqualTo: projectId,
      orderBy: orderBy ?? 'created_at',
      descending: descending,
    );
  }

  Stream<List<Note>> getNotesStream() => _streamByType<Note>(ArtifactType.note);
  Stream<List<FolderModel>> getFoldersStream() => _streamByType<FolderModel>(ArtifactType.folder);
  Stream<List<CanvasModel>> getCanvasesStream() => _streamByType<CanvasModel>(ArtifactType.canvas);

  Stream<List<T>> _streamByType<T extends Artifact>(ArtifactType type) {
    // Server-side scope by project_id; client-side post-filter by type.
    return queryStream(
      field: 'project_id',
      isEqualTo: projectId,
      orderBy: 'created_at',
    ).map((items) => items.whereType<T>().toList());
  }

  @override
  Future<void> add(Artifact item, {bool suppressStream = false}) async {
    final uniqueTitle = await _generateUniqueName(item.title);
    final id = item.id.isEmpty ? const Uuid().v4() : item.id;
    final newItem = item.copyWith(id: id, title: uniqueTitle);
    return super.add(newItem, suppressStream: suppressStream);
  }

  Future<String> _generateUniqueName(String baseTitle) async {
    try {
      final existingTitles = (await getAll())
          .where((item) => item.title.startsWith(baseTitle))
          .map((canvas) => canvas.title)
          .toSet();

      if (!existingTitles.contains(baseTitle)) return baseTitle;

      int counter = 1;
      String candidateTitle;
      do {
        candidateTitle = '$baseTitle ($counter)';
        counter++;
      } while (existingTitles.contains(candidateTitle));

      return candidateTitle;
    } catch (e) {
      debugPrint('Error generating unique name: $e');
      return '$baseTitle (${DateTime.now().millisecondsSinceEpoch})';
    }
  }

  /// Get breadcrumb trail from root down to the specified item.
  /// Returns list with root item at index 0, target item at last index.
  Future<List<Artifact>> getBreadcrumbTrail(String itemId) async {
    if (itemId.isEmpty) return [];

    final breadcrumbs = <Artifact>[];
    final visitedIds = <String>{};
    String currentId = itemId;

    while (currentId.isNotEmpty) {
      if (visitedIds.contains(currentId)) {
        debugPrint('Circular reference detected in item hierarchy at: $currentId');
        break;
      }
      visitedIds.add(currentId);

      try {
        final item = await get(currentId);
        if (item == null) {
          debugPrint('Item not found: $currentId');
          break;
        }
        breadcrumbs.insert(0, item);
        currentId = item.parent;
      } catch (e) {
        debugPrint('Error getting item $currentId for breadcrumb trail: $e');
        break;
      }
    }

    return breadcrumbs;
  }

  Future<Artifact?> getParent(Artifact item) async => item.parent.isEmpty ? null : get(item.parent);

  Future<List<Artifact>> getSiblings(Artifact item) async =>
      query(field: 'parent_folder_id', isEqualTo: item.parent.isEmpty ? null : item.parent);

  Future<List<Artifact>> getChildren(String parentId) async =>
      query(field: 'parent_folder_id', isEqualTo: parentId);

  /// Deleting an artifact orphans its non-cascading dependents up-front, then
  /// removes the row. The Phase B schema sets ON DELETE CASCADE on
  /// parent_folder_id, so children would otherwise be deleted with the parent;
  /// we orphan them first to preserve the legacy "delete folder, keep contents"
  /// behaviour from the Firestore implementation.
  @override
  Future<void> delete(dynamic item) async {
    final String id;
    if (item is String) {
      id = item;
    } else if (item is Artifact) {
      id = getIdFromItem(item);
    } else {
      throw ArgumentError('Parameter must be Artifact or String: $item');
    }

    final children = await getChildren(id);
    for (final child in children) {
      try {
        await update(child.copyWith(parentId: ''));
      } catch (e) {
        debugPrint('Error orphaning item ${child.id}: $e');
      }
    }

    await super.delete(id);
  }

  /// Cascading delete — children and grandchildren go with the row, courtesy of
  /// the schema's ON DELETE CASCADE on parent_folder_id.
  Future<void> deleteRecursive(String itemId) async => super.delete(itemId);

  Stream<List<T>> getChildrenStreamByType<T extends Artifact>(
    String parentId,
    ArtifactType type,
  ) {
    return queryStream(
      field: 'parent_folder_id',
      isEqualTo: parentId,
      orderBy: 'created_at',
    ).map((items) => items.whereType<T>().toList());
  }

  Stream<List<FolderModel>> getChildFoldersStream(String parentId) =>
      getChildrenStreamByType<FolderModel>(parentId, ArtifactType.folder);
}
