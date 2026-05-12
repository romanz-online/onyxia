import 'package:onyxia/export.dart';
import 'dart:async';

final artifactsProvider =
    NotifierProvider<ArtifactsTreeNotifier, List<Artifact>>(
  ArtifactsTreeNotifier.new,
);

final artifactsLoadedProvider = Provider<bool>((ref) {
  final projectId =
      ref.watch(projectsProvider.select((s) => s.selectedProject?.id));
  if (projectId == null) return true;
  final dataReceived = ref.watch(artifactsReceivedProvider(projectId));
  final hasError = ref.watch(artifactsErrorProvider(projectId));
  return dataReceived && !hasError;
});

final artifactsReceivedProvider =
    NotifierProvider.family<ArtifactsReceivedNotifier, bool, String>(
  (_) => ArtifactsReceivedNotifier(),
);

class ArtifactsReceivedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final artifactsErrorProvider =
    NotifierProvider.family<ArtifactsErrorNotifier, bool, String>(
  (_) => ArtifactsErrorNotifier(),
);

class ArtifactsErrorNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final wikiLinkTitlesProvider = Provider<List<String>>(
    (ref) => ref.watch(artifactsProvider).map((item) => item.name).toList());

class ArtifactsTreeNotifier extends Notifier<List<Artifact>> {
  late ArtifactsRepository _repository;
  String? _projectId;

  @override
  List<Artifact> build() {
    _projectId =
        ref.watch(projectsProvider.select((s) => s.selectedProject?.id));
    _repository = ArtifactsRepository(projectId: _projectId);

    if (_projectId == null) return [];

    final sub = _repository.getStream().listen(
      (data) {
        state = data;
        ref
            .read(artifactsReceivedProvider(_projectId!).notifier)
            .set(true);
        ref.read(artifactsErrorProvider(_projectId!).notifier).set(false);
      },
      onError: (error) {
        debugPrint('ArtifactsTreeNotifier: Error listening: $error');
        ref
            .read(artifactsReceivedProvider(_projectId!).notifier)
            .set(true);
        ref.read(artifactsErrorProvider(_projectId!).notifier).set(true);
      },
    );
    ref.onDispose(sub.cancel);

    return [];
  }

  String? get projectId => _projectId;

  Artifact? getItemById(String id) => state.firstWhereOrNull((e) => e.id == id);

  Future<void> addItems(List<Artifact> items) async {
    if (items.isEmpty) return;
    await _repository.add(items);
  }

  Future<void> addItem(Artifact item) async => await _repository.add([item]);

  Future<void> deleteItem(String itemId, BuildContext context) async {
    if (itemId.isEmpty) return;

    List<String> collectDescendantIds(String parentId) {
      final children =
          state.where((e) => e.parentFolderId == parentId).toList();
      final ids = children.map((c) => c.id).toList();
      for (final child in children) {
        ids.addAll(collectDescendantIds(child.id));
      }
      return ids;
    }

    final idsToDelete = [itemId, ...collectDescendantIds(itemId)];

    final selectedItem = ref.read(selectedArtifactProvider);
    if (selectedItem != null && idsToDelete.contains(selectedItem.id)) {
      ref.read(selectedArtifactNameProvider.notifier).set(null);
      context.go('/project/$_projectId/${Routes.graph}');
    }

    state = state.where((e) => !idsToDelete.contains(e.id)).toList();

    await _repository.deleteMultiple(idsToDelete);
  }

  // --- Re-parent ---

  bool updateParent(String itemId, {required String newParentId}) {
    final item = state.firstWhereOrNull((e) => e.id == itemId);
    if (item == null) return false;
    if (item.parentFolderId == newParentId) return false;

    if (item.type == ArtifactType.folder && newParentId.isNotEmpty) {
      final newParent = state.firstWhereOrNull((e) => e.id == newParentId);
      if (newParent == null || newParent.type != ArtifactType.folder)
        return false;
    }

    final updated = item.copyWith(parentFolderId: newParentId);
    updateItemState(updated);
    _repository.update(updated);
    return true;
  }

  // --- Update ---

  void updateItemState(Artifact item) {
    final index = state.indexWhere((e) => e.id == item.id);
    if (index == -1) return;
    final updated = List<Artifact>.from(state);
    updated[index] = item;
    state = updated;
  }

  void updateItem(Artifact item) {
    updateItemState(item);
    _repository.update(item);
  }

  void updateItems({List<Artifact> items = const []}) {
    for (final item in items) {
      updateItemState(item);
    }
    _repository.updateMultiple(items.isEmpty ? state : items);
  }
}
