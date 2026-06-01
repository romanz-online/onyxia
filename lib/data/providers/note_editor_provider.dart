import 'dart:async';

import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/export.dart';

// TODO: it would be better to keep all of noteEditorProvider's functionality within the actual editor workspace since that's the only area it's being used in anyway. i'm not even actually sure if i need a provider at all since it's not going cross-file.

/// Creates a NoteNotifier for the currently selected Note item.
final noteEditorProvider =
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

  @override
  Future<NoteEditorState> build() async {
    final selectedNoteId = ref.watch(
      selectedArtifactProvider.select((a) => a is NoteArtifact ? a.id : null),
    );
    _vaultId = ref.watch(selectedVaultProvider.select((p) => p?.id));

    ref.onDispose(() {
      final controller = _controller;
      _controller = null;
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
}
