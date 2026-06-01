import 'dart:async';

import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/export.dart';

// TODO: having a selectedNoteStateProvider separate from selectedArtifactProvider kind of sucks and is confusing. it would be better to keep all of selectedNoteStateProvider's functionality within the actual editor workspace since that's the only area it's being used in anyway

/// Creates a NoteNotifier for the currently selected Note item.
final selectedNoteStateProvider =
    AsyncNotifierProvider.autoDispose<NoteNotifier, NoteState>(
      NoteNotifier.new,
    );

class NoteState {
  final NoteArtifact? note;
  final BardController? bardController;
  final BardCollabConfig? collabConfig;

  const NoteState({this.note, this.bardController, this.collabConfig});

  NoteState copyWith({
    NoteArtifact? note,
    BardController? bardController,
    BardCollabConfig? collabConfig,
  }) {
    return NoteState(
      note: note ?? this.note,
      bardController: bardController ?? this.bardController,
      collabConfig: collabConfig ?? this.collabConfig,
    );
  }
}

class NoteNotifier extends AsyncNotifier<NoteState> {
  String? _vaultId;
  BardController? _controller;
  StreamController<Uint8List>? _remoteOpsController;

  @override
  Future<NoteState> build() async {
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

    if (selectedNoteId == null || _vaultId == null) {
      return const NoteState();
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const NoteState();

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
    if (!ref.mounted) return const NoteState();

    final initialOps = await opsRepo.opBytesFor(
      note.id,
      sinceSeq: snap?.maxOpSeq,
    );
    if (!ref.mounted) return const NoteState();

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

    return NoteState(
      note: note,
      bardController: controller,
      collabConfig: collab,
    );
  }
}
