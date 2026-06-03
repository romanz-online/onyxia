import 'dart:async';

import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/export.dart';

/// Creates a NoteNotifier for the currently selected Note item.
final noteEditorStateProvider =
    AsyncNotifierProvider.autoDispose<NoteEditorStateNotifier, NoteEditorState>(
      NoteEditorStateNotifier.new,
    );

class NoteEditorState {
  final NoteArtifact? note;
  final BardController? bardController;
  final BardCollabConfig? collabConfig;

  const NoteEditorState({this.note, this.bardController, this.collabConfig});

  NoteEditorState copyWith({
    NoteArtifact? note,
    BardController? bardController,
    BardCollabConfig? collabConfig,
  }) {
    return NoteEditorState(
      note: note ?? this.note,
      bardController: bardController ?? this.bardController,
      collabConfig: collabConfig ?? this.collabConfig,
    );
  }
}

class NoteEditorStateNotifier extends AsyncNotifier<NoteEditorState> {
  String? _vaultId;
  BardController? _controller;
  StreamController<Uint8List>? _remoteOpsController;
  NoteArtifact? _note;

  // Debounced writeback of the converged editor text into artifacts.body.content.
  // body.content is a denormalized read-cache (the constellation reads it; the
  // editor itself hydrates from snapshot+ops, not from it). Refreshing it also
  // fires the artifacts UPDATE triggers that bump artifact + vault updated_at.
  Timer? _writebackTimer;
  String? _lastWrittenContent;
  static const _writebackDebounce = Duration(seconds: 2);

  @override
  Future<NoteEditorState> build() async {
    final selectedNoteId = ref.watch(
      selectedArtifactProvider.select((a) => a is NoteArtifact ? a.id : null),
    );
    _vaultId = ref.watch(selectedVaultProvider.select((p) => p?.id));

    ref.onDispose(() {
      _writebackTimer?.cancel();
      _writebackTimer = null;
      final controller = _controller;
      final note = _note;
      final vaultId = _vaultId;
      _controller = null;
      // Final writeback so edits made in the last debounce window aren't lost
      // on note switch / editor close. onDispose can't await — issue and go.
      if (controller != null && note != null && vaultId != null) {
        final text = controller.text;
        if (text != _lastWrittenContent) {
          _lastWrittenContent = text;
          ArtifactsRepository(
            vaultId: vaultId,
          ).update([note.copyWith(content: text)]);
        }
      }
      _remoteOpsController?.close();
      _remoteOpsController = null;
      if (controller != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.dispose();
        });
      }
    });

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (selectedNoteId == null || _vaultId == null || userId == null) {
      return const NoteEditorState();
    }

    final note = ref.read(selectedArtifactProvider) as NoteArtifact;
    _note = note;
    _lastWrittenContent = note.content;
    final opsRepo = ArtifactOpsRepository(vaultId: _vaultId);
    final snapsRepo = ArtifactSnapshotsRepository(vaultId: _vaultId);

    // Subscribe to realtime BEFORE the snapshot+catch-up fetches. With two
    // concurrent writers, any op committed during the fetch window would
    // otherwise be missed (not in catch-up, not in the realtime stream that
    // hasn't started yet) and cause CausallyNotReady on a later dep reference.
    // The single-listener controller buffers events arriving during the fetch
    // so the engine drains them in order after applying the catch-up ops.
    final remoteOps = StreamController<Uint8List>();
    _remoteOpsController = remoteOps;
    final supabaseSub = opsRepo.opByteStreamFor(note.id).listen(remoteOps.add);
    ref.onDispose(supabaseSub.cancel);

    final snap = await snapsRepo.latestFor(note.id);
    if (!ref.mounted) return const NoteEditorState();

    final initialOps = await opsRepo.opBytesFor(
      note.id,
      sinceSeq: snap?.maxOpSeq,
    );
    if (!ref.mounted) return const NoteEditorState();

    final collab = BardCollabConfig(
      initialSnapshot: snap?.snapshotBytes,
      initialOps: initialOps,
      remoteOps: remoteOps.stream,
      onLocalOp: (bytes) {
        // Fire-and-forget; failures should surface via global error handling.
        opsRepo.append(note.id, bytes);
        _scheduleContentWriteback();
      },
    );

    final snapSub = snapsRepo.changeStreamFor(note.id).listen((_) {
      if (ref.mounted) ref.invalidateSelf();
    });
    ref.onDispose(snapSub.cancel);

    final controller = BardController(text: '');
    _controller = controller;

    return NoteEditorState(
      note: note,
      bardController: controller,
      collabConfig: collab,
    );
  }

  void _scheduleContentWriteback() {
    _writebackTimer?.cancel();
    _writebackTimer = Timer(_writebackDebounce, _flushContentWriteback);
  }

  Future<void> _flushContentWriteback() async {
    _writebackTimer = null;
    final controller = _controller;
    final note = _note;
    final vaultId = _vaultId;
    if (controller == null || note == null || vaultId == null) return;
    final text = controller.text;
    if (text == _lastWrittenContent) return; // nothing changed since last write
    _lastWrittenContent = text;
    try {
      await ArtifactsRepository(
        vaultId: vaultId,
      ).update([note.copyWith(content: text)]);
    } catch (_) {
      // Let a later edit retry the write rather than swallowing the change.
      if (_lastWrittenContent == text) _lastWrittenContent = null;
    }
  }
}
