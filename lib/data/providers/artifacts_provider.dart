import 'package:onyxia/export.dart';

final artifactsProvider =
    StateNotifierProvider<ArtifactsTreeNotifier, List<Artifact>>((ref) {
  final projectId =
      ref.watch(projectsProvider.select((s) => s.selectedProject.id));
  return ArtifactsTreeNotifier(
    ArtifactsRepository(projectId: projectId),
    projectId,
    ref: ref,
  );
});

final artifactsLoadedProvider = Provider<bool>((ref) {
  final projectId =
      ref.watch(projectsProvider.select((s) => s.selectedProject.id));
  if (projectId.isEmpty) return true;
  final dataReceived = ref.watch(artifactsReceivedProvider(projectId));
  final hasError = ref.watch(artifactsErrorProvider(projectId));
  return dataReceived && !hasError;
});

final artifactsReceivedProvider =
    StateProvider.family<bool, String>((ref, projectId) => false);
final artifactsErrorProvider =
    StateProvider.family<bool, String>((ref, projectId) => false);

final wikiLinkTitlesProvider = Provider<List<String>>((ref) {
  return ref.watch(artifactsProvider).map((item) => item.title).toList();
});

class ArtifactsTreeNotifier extends StateNotifier<List<Artifact>> {
  final ArtifactsRepository repository;
  final String projectId;
  StreamSubscription<List<Artifact>>? _subscription;
  List<Artifact> _snapshot = [];
  final Ref ref;
  bool _isOperationInProgress = false;
  final StateProviderFamily<bool, String> _receivedProvider;
  final StateProviderFamily<bool, String> _errorProvider;

  ArtifactsTreeNotifier(
    this.repository,
    this.projectId, {
    required this.ref,
    StateProviderFamily<bool, String>? receivedProvider,
    StateProviderFamily<bool, String>? errorProvider,
  })  : _receivedProvider = receivedProvider ?? artifactsReceivedProvider,
        _errorProvider = errorProvider ?? artifactsErrorProvider,
        super([]) {
    _listen();
  }

  void _listen() {
    _subscription?.cancel();
    if (projectId.isEmpty) return;

    _subscription = repository.getStream().listen(
      (data) {
        _snapshot = data;
        ref.read(_receivedProvider(projectId).notifier).state = true;
        ref.read(_errorProvider(projectId).notifier).state = false;

        if (_isOperationInProgress) return;

        if (!listEquals(state, data)) {
          state = data;
        }
      },
      onError: (error) {
        debugPrint('TreeNotifier: Error listening: $error');
        ref.read(_receivedProvider(projectId).notifier).state = true;
        ref.read(_errorProvider(projectId).notifier).state = true;
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // --- Lookup ---

  Artifact? getItemByTitle(String title) =>
      _snapshot.firstWhereOrNull((e) => e.title == title);

  Artifact? getItemById(String id) =>
      _snapshot.firstWhereOrNull((e) => e.id == id);

  void syncFromRemote() {
    if (!listEquals(state, _snapshot)) {
      state = List.from(_snapshot);
    }
  }

  List<Artifact> getChildren(Artifact parent) =>
      state.where((e) => e.parentFolderId == parent.id).toList();

  // --- Add ---

  Future<void> addItems(List<Artifact> items) async {
    if (items.isEmpty) return;

    final itemsWithIds = items
        .map((e) => e.id.isEmpty ? e.copyWith(id: const Uuid().v4()) : e)
        .toList();

    state = [
      ...itemsWithIds,
      ...state.where((e) => !itemsWithIds.any((n) => n.id == e.id)),
    ];

    _isOperationInProgress = true;
    try {
      await repository.add(itemsWithIds);
    } finally {
      _isOperationInProgress = false;
    }
  }

  Future<void> addItem(Artifact item) async {
    _isOperationInProgress = true;
    try {
      await repository.add([item]);
    } finally {
      _isOperationInProgress = false;
    }
  }

  // --- Delete ---

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
      ref.read(selectedArtifactProvider.notifier).state = null;
      context.go('/project/$projectId/${Routes.graph}');
    }

    state = state.where((e) => !idsToDelete.contains(e.id)).toList();

    _isOperationInProgress = true;
    try {
      await repository.deleteMultiple(idsToDelete);
    } finally {
      _isOperationInProgress = false;
    }
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
    repository.update(updated);
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
    repository.update(item);
  }

  void updateItems({List<Artifact> items = const []}) {
    for (final item in items) {
      updateItemState(item);
    }
    repository.updateMultiple(items.isEmpty ? state : items);
  }
}
