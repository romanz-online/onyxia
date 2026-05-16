import 'package:onyxia/bard/markdown_parser.dart';
import 'package:onyxia/bard/markdown_span.dart';
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
  String? _vaultId;
  late ArtifactsRepository _repository;

  @override
  Stream<List<Artifact>> build() {
    _vaultId = ref.watch(selectedVaultProvider.select((p) => p?.id));
    _repository = ArtifactsRepository(vaultId: _vaultId);
    if (_vaultId == null) return Stream.value(const <Artifact>[]);
    return _repository.getStream();
  }

  List<Artifact> get _items => state.value ?? const <Artifact>[];

  Artifact? getItemById(String id) =>
      _items.firstWhereOrNull((e) => e.id == id);

  Future<void> addItems(List<Artifact> items) async {
    if (items.isEmpty) return;
    await _repository.add(items);
  }

  Future<void> addItem(Artifact item) async => await _repository.add([item]);

  Future<void> deleteItem(String itemId) async {
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

    final router = ref.read(routerProvider);
    final urlSelectedName =
        router.routerDelegate.currentConfiguration.pathParameters['selectedId'];
    final selectedItem = urlSelectedName == null
        ? null
        : _items.firstWhereOrNull((a) => a.name == urlSelectedName);
    if (selectedItem != null && idsToDelete.contains(selectedItem.id)) {
      router.go('/vault/$_vaultId/${Routes.graph}');
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
    _repository.update([item]);
  }

  Future<void> updateItems({List<Artifact> items = const []}) async {
    for (final item in items) {
      updateItemState(item);
    }
    await _repository.update(items.isEmpty ? _items : items);
  }

  // --- Rename ---

  /// Renames [item] to [newName]. Validates first; on rejection returns the
  /// error message and performs no writes. On success writes the renamed
  /// item, rewrites `[[oldName]]` wiki-links in every note's content
  /// (including the renamed item's own content), and navigates the URL if
  /// the user is currently viewing this item. Returns `null` on success or
  /// no-op (empty / unchanged name).
  Future<String?> renameItem(Artifact item, String newName) async {
    final cleaned = ItemTitleValidationService.correctTitle(newName.trim());
    if (cleaned.isEmpty || cleaned == item.name) return null;
    final err =
        ItemTitleValidationService.errorMessage(_items, cleaned, item.id);
    if (err != null) return err;

    final oldName = item.name;
    final renamed = item.copyWith(name: cleaned);

    final batch = <Artifact>[];
    for (final a in _items) {
      Artifact updated = a.id == item.id ? renamed : a;
      if (updated is NoteArtifact) {
        final rewritten = _rewriteWikiLinksInContent(
          updated.content,
          oldName: oldName,
          newName: cleaned,
        );
        if (rewritten != updated.content) {
          updated = updated.copyWith(content: rewritten);
        }
      }
      if (updated != a) batch.add(updated);
    }

    // Apply local state + URL synchronously so selectedArtifactProvider
    // never sees state==NewName while url==OldName (the flash window).
    batch.forEach((e) => updateItemState(e));

    final router = ref.read(routerProvider);
    final urlSelectedId =
        router.routerDelegate.currentConfiguration.pathParameters['selectedId'];
    if (urlSelectedId == oldName) {
      final vaultId = ref.read(selectedVaultProvider.select((p) => p?.id));
      router.go(renamed.navigationUrl(vaultId));
    }

    await _repository.update(batch);

    return null;
  }
}

// Rewrites `[[oldName]]` wiki-links to `[[newName]]` using the markdown
// parser. The parser-based approach correctly handles unclosed `[[name`
// links (auto-closed at newline/EOF) and avoids false-positive prefix
// matches against other names — a literal `replaceAll('[[bar', ...)` would
// have clobbered `[[bar two`.
String _rewriteWikiLinksInContent(
  String content, {
  required String oldName,
  required String newName,
}) {
  if (!content.contains('[[')) return content;
  final spans = parseMarkdown(content)
      .inlineSpans
      .where((s) => s.type == MarkdownFormatType.wikiLink)
      .toList();
  if (spans.isEmpty) return content;

  final buf = StringBuffer();
  int cursor = 0;
  bool changed = false;
  for (final s in spans) {
    if (content.substring(s.contentStart, s.contentEnd) != oldName) continue;
    buf.write(content.substring(cursor, s.contentStart));
    buf.write(newName);
    cursor = s.contentEnd;
    changed = true;
  }
  if (!changed) return content;
  buf.write(content.substring(cursor));
  return buf.toString();
}
