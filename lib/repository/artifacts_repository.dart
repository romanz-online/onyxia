import 'package:onyxia/export.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArtifactsRepository extends BaseFirestoreRepository<Artifact> {
  ArtifactsRepository({required super.projectId});

  @override
  String get collectionPath => 'projects/$projectId/artifacts';

  @override
  Artifact fromMap(Map<String, dynamic> map) => Artifact.factory(map);

  @override
  Map<String, dynamic> toMap(Artifact item) => item.toMap();

  @override
  String getIdFromItem(Artifact item) => item.id;

  @override
  bool get updateProjectMetadata => true;

  @override
  Stream<List<Artifact>> getStream({Query? query}) => queryStream(orderBy: 'createdAt');

  Stream<List<Note>> getNotesStream() {
    return queryStream(
      field: 'type',
      isEqualTo: ArtifactType.note.value,
      orderBy: 'createdAt',
    ).map((items) => items.whereType<Note>().toList());
  }

  Stream<List<FolderModel>> getFoldersStream() {
    return queryStream(
      field: 'type',
      isEqualTo: ArtifactType.folder.value,
      orderBy: 'createdAt',
    ).map((items) => items.whereType<FolderModel>().toList());
  }

  Stream<List<CanvasModel>> getCanvasesStream() {
    return queryStream(
      field: 'type',
      isEqualTo: ArtifactType.canvas.value,
      orderBy: 'createdAt',
    ).map((items) => items.whereType<CanvasModel>().toList());
  }

  @override
  Future<void> add(Artifact item, {bool suppressStream = false}) async {
    final uniqueTitle = await _generateUniqueName(item.title);
    final id = item.id.isEmpty ? const Uuid().v4() : item.id;
    final newItem = item.copyWith(id: id, title: uniqueTitle);

    // Call parent's add() which will apply _create() to inject createdBy automatically
    return super.add(newItem, suppressStream: suppressStream);
  }

  Future<String> _generateUniqueName(String baseTitle) async {
    try {
      final existingTitles =
          (await query()).where((item) => item.title.startsWith(baseTitle)).map((canvas) => canvas.title).toSet();

      // If base title doesn't exist, use it
      if (!existingTitles.contains(baseTitle)) return baseTitle;

      // Find next available numbered version
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

  /// Get breadcrumb trail from root down to the specified item
  /// Returns list with root item at index 0, target item at last index
  Future<List<Artifact>> getBreadcrumbTrail(String itemId) async {
    if (itemId.isEmpty) return [];

    final breadcrumbs = <Artifact>[];
    final visitedIds = <String>{};
    String currentId = itemId;

    while (currentId.isNotEmpty) {
      // Prevent infinite loops from circular references
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

        // Insert at beginning to build root-first order
        breadcrumbs.insert(0, item);
        currentId = item.parent;
      } catch (e) {
        debugPrint('Error getting item $currentId for breadcrumb trail: $e');
        break;
      }
    }

    return breadcrumbs;
  }

  Future<Artifact?> getParent(Artifact item) async => await get(item.parent);

  Future<List<Artifact>> getSiblings(Artifact item) async =>
      (await query()).where((e) => e.parent == item.parent).toList();

  Future<List<Artifact>> getChildren(String parentId) async =>
      (await query()).where((e) => e.parent == parentId).toList();

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

    final children = await FirebaseFirestore.instance.collection(collectionPath).where('parentId', isEqualTo: id).get();

    for (final doc in children.docs) {
      try {
        await update(Artifact.factory(doc.data()).copyWith(parentId: ''));
      } catch (e) {
        debugPrint('Error orphaning item ${doc.id}: $e');
      }
    }

    await FirebaseFirestore.instance.collection(collectionPath).doc(id).delete();
  }

  Future<void> deleteRecursive(String itemId) async {
    final children =
        await FirebaseFirestore.instance.collection(collectionPath).where('parentId', isEqualTo: itemId).get();

    for (final child in children.docs) {
      await deleteRecursive(child.id);
    }

    // final nonFolders = await FirebaseFirestore.instance
    //     .collection(collectionPath)
    //     .where('type', isNotEqualTo: ArtifactType.folder.value)
    //     .where('parentId', isEqualTo: itemId)
    //     .get();

    // for (final doc in nonFolders.docs) {
    //   try {
    //     await update(Artifact.factory(doc.data())
    //         .archive(FirebaseAuth.instance.currentUser?.uid ?? 'system')
    //         .copyWith(parentId: ''));
    //   } catch (e) {
    //     debugPrint('Error archiving item ${doc.id}: $e');
    //   }
    // }

    // Finally, delete the folder itself
    await FirebaseFirestore.instance.collection(collectionPath).doc(itemId).delete();
  }

  Stream<List<T>> getChildrenStreamByType<T extends Artifact>(
    String parentId,
    ArtifactType type,
  ) {
    return queryStream(
      field: 'parentId',
      isEqualTo: parentId,
      orderBy: 'createdAt',
    ).map((items) => items.whereType<T>().toList());
  }

  Stream<List<FolderModel>> getChildFoldersStream(String parentId) =>
      getChildrenStreamByType<FolderModel>(parentId, ArtifactType.folder);
}
