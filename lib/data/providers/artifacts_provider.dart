import 'package:onyxia/export.dart';

final artifactsProvider =
    StreamNotifierProvider<ArtifactsTreeNotifier, List<Artifact>>(
  ArtifactsTreeNotifier.new,
);

final wikiLinkTitlesProvider = Provider<List<String>>((ref) =>
    (ref.watch(artifactsProvider).value ?? const <Artifact>[])
        .map((item) => item.name)
        .toList());

class ArtifactsTreeNotifier extends StreamNotifier<List<Artifact>> {
  String? _projectId;
  late ArtifactsRepository _repository;

  @override
  Stream<List<Artifact>> build() {
    _projectId = ref.watch(selectedProjectProvider.select((p) => p?.id));
    _repository = ArtifactsRepository(projectId: _projectId);
    if (_projectId == null) return Stream.value(const <Artifact>[]);
    return _repository.getStream();
  }

  String? get projectId => _projectId;

  List<Artifact> get _items => state.value ?? const <Artifact>[];

  Artifact? getItemById(String id) =>
      _items.firstWhereOrNull((e) => e.id == id);

  Future<void> addItems(List<Artifact> items) async {
    if (items.isEmpty) return;
    await _repository.add(items);
  }

  Future<void> addItem(Artifact item) async => await _repository.add([item]);

  Future<void> deleteItem(String itemId, BuildContext context) async {
    if (itemId.isEmpty) return;

    List<String> collectDescendantIds(String parentId) {
      final children =
          _items.where((e) => e.parentFolderId == parentId).toList();
      final ids = children.map((c) => c.id).toList();
      for (final child in children) {
        ids.addAll(collectDescendantIds(child.id));
      }
      return ids;
    }

    final idsToDelete = [itemId, ...collectDescendantIds(itemId)];

    final selectedItem = ref.read(selectedArtifactProvider);
    if (selectedItem != null && idsToDelete.contains(selectedItem.id)) {
      context.go('/project/$_projectId/${Routes.graph}');
    }

    state = AsyncData(
      _items.where((e) => !idsToDelete.contains(e.id)).toList(),
    );

    await _repository.deleteMultiple(idsToDelete);
  }

  // --- Re-parent ---

  bool updateParent(String itemId, {required String newParentId}) {
    final item = _items.firstWhereOrNull((e) => e.id == itemId);
    if (item == null) return false;
    if (item.parentFolderId == newParentId) return false;

    if (item.type == ArtifactType.folder && newParentId.isNotEmpty) {
      final newParent = _items.firstWhereOrNull((e) => e.id == newParentId);
      if (newParent == null || newParent.type != ArtifactType.folder)
        return false;
    }

    updateItem(item.copyWith(parentFolderId: newParentId));
    return true;
  }

  // --- Update ---

  void updateItemState(Artifact item) {
    final items = _items;
    final index = items.indexWhere((e) => e.id == item.id);
    if (index == -1) return;
    final updated = List<Artifact>.from(items);
    updated[index] = item;
    state = AsyncData(updated);
  }

  void updateItem(Artifact item) {
    updateItemState(item);
    _repository.update(item);
  }

  void updateItems({List<Artifact> items = const []}) {
    for (final item in items) {
      updateItemState(item);
    }
    _repository.updateMultiple(items.isEmpty ? _items : items);
  }
}
