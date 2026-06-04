import 'package:crdt_lf/crdt_lf.dart';
import 'package:onyxia/bard/markdown_parser.dart';
import 'package:onyxia/bard/markdown_span.dart';
import 'package:onyxia/export.dart';

final artifactsProvider =
    StreamNotifierProvider<ArtifactsTreeNotifier, List<Artifact>>(
      ArtifactsTreeNotifier.new,
    );

final wikiLinkTitlesProvider = Provider<List<String>>(
  (ref) => (ref.watch(artifactsProvider).value ?? const <Artifact>[])
      .map((item) => item.name)
      .toList(),
);

/// Unfiltered wiki-link graph derived from note content. Cached off
/// [artifactsProvider] so it re-extracts only when artifacts actually change
/// (e.g. a content writeback), not on every constellation widget rebuild /
/// filter toggle. The constellation applies its display filters on top.
typedef WikiGraph = ({
  List<String> nodeNames,
  List<({String source, String target})> edges,
  Set<String> zombieNames,
});

final wikiGraphProvider = Provider<WikiGraph>((ref) {
  final items = ref.watch(artifactsProvider).value ?? const <Artifact>[];
  final titleLookup = <String, String>{
    for (final i in items) i.name.toLowerCase(): i.name,
  };
  final nodeNames = items.map((i) => i.name).toList();
  final edges = <({String source, String target})>[];
  final zombieNames = <String>{};

  for (final item in items) {
    if (item is! NoteArtifact) continue;
    for (final rawLink in extractWikiLinks(item.content)) {
      final canonical = titleLookup[rawLink.toLowerCase()];
      if (canonical != null && canonical != item.name) {
        edges.add((source: item.name, target: canonical));
      } else if (canonical == null && rawLink.isNotEmpty) {
        zombieNames.add(rawLink);
        edges.add((source: item.name, target: rawLink));
      }
    }
  }

  return (nodeNames: nodeNames, edges: edges, zombieNames: zombieNames);
});

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
      final children = _items
          .where((e) => e.parentFolderId == parentId)
          .toList();
      final ids = children.map((c) => c.id).toList();
      for (final child in children) {
        ids.addAll(collectDescendantIds(child.id));
      }
      return ids;
    }

    final idsToDelete = [itemId, ...collectDescendantIds(itemId)];

    // Snapshot before the optimistic state mutation below removes these items.
    final storagePathsToDelete = _items
        .whereType<ImageArtifact>()
        .where((e) => idsToDelete.contains(e.id))
        .map((e) => e.storagePath)
        .where((p) => p.isNotEmpty)
        .toList();

    final urlSelectedName = ref
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .pathParameters['selectedId'];
    final selectedItem = _items.firstWhereOrNull(
      (a) => a.name == urlSelectedName,
    );
    if (selectedItem != null && idsToDelete.contains(selectedItem.id)) {
      ref.read(routerProvider).go(Routes.vaultUrl(_vaultId));
    }

    await _repository.deleteMultiple(idsToDelete);
    await ImageService.deleteImages(storagePathsToDelete);
  }

  // --- Re-parent ---

  bool updateParent(String itemId, {required String newParentId}) {
    final item = _items.firstWhereOrNull((e) => e.id == itemId);
    if (item == null) return false;
    if (item.parentFolderId == newParentId) return false;

    if (item.type == .folder && newParentId.isNotEmpty) {
      final newParent = _items.firstWhereOrNull((e) => e.id == newParentId);
      if (newParent == null || newParent.type != .folder) return false;
    }

    updateItem(item.copyWith(parentFolderId: newParentId));
    return true;
  }

  // --- Update ---

  void updateItemState(Artifact item) {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index == -1) return;
    final updated = List<Artifact>.from(_items);
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
  /// (including the renamed item's own content), rebuilds the CRDT snapshot
  /// for every note whose content was rewritten so the change survives load,
  /// and navigates the URL if the user is currently viewing this item.
  /// Returns `null` on success or no-op (empty / unchanged name).
  Future<String?> renameItem(Artifact item, String newName) async {
    final cleaned = ItemNameValidationService.correctTitle(newName.trim());
    if (cleaned.isEmpty || cleaned == item.name) return null;
    final err = ItemNameValidationService.validate(_items, cleaned, item.id);
    if (err != null) return err;

    final oldName = item.name;
    final renamed = item.copyWith(name: cleaned);

    final batch = <Artifact>[];
    final rewrittenNotes = <NoteArtifact>[];
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
          rewrittenNotes.add(updated);
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
      router.go(Routes.artifactUrl(vaultId: vaultId, name: renamed.name));
    }

    await _repository.update(batch);

    // BardEditor hydrates from artifact_snapshots + artifact_ops, not from
    // NoteArtifact.content. Without rebuilding the snapshot, the new content
    // is silently overwritten on next load by replaying the pre-rename ops.
    if (rewrittenNotes.isNotEmpty && _vaultId != null) {
      await _rebuildSnapshotsForRewrittenNotes(rewrittenNotes, _vaultId!);
    }

    return null;
  }

  /// For each note whose `content` was just rewritten, replaces its CRDT
  /// snapshot with one built from the new content and caps `max_op_seq` so the
  /// load path skips the now-superseded ops. Mirrors the pattern in
  /// `porting_service._importMarkdown`.
  Future<void> _rebuildSnapshotsForRewrittenNotes(
    List<NoteArtifact> notes,
    String vaultId,
  ) async {
    final snapsRepo = ArtifactSnapshotsRepository(vaultId: vaultId);
    final opsRepo = ArtifactOpsRepository(vaultId: vaultId);
    for (final note in notes) {
      final maxSeq = await opsRepo.maxSeqFor(note.id);
      final doc = CRDTDocument(peerId: PeerId.generate());
      if (note.content.isNotEmpty) {
        CRDTFugueTextHandler(doc, BardCodec.handlerKey).insert(0, note.content);
      }
      final snap = doc.takeSnapshot(pruneHistory: false);
      await snapsRepo.upsert(
        ArtifactSnapshot(
          artifactId: note.id,
          vaultId: vaultId,
          snapshotBytes: BardCodec.encodeSnapshot(snap),
          versionVector: snap.versionVector.toJson(),
          maxOpSeq: maxSeq,
        ),
      );
    }
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
  final spans = parseMarkdown(
    content,
  ).inlineSpans.where((s) => s.type == MarkdownFormatType.wikiLink).toList();
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
