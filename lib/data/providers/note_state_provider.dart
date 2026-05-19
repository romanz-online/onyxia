import 'dart:async';

import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/export.dart';

class NoteState {
  final NoteArtifact? note;
  final BardController? bardController;
  final FocusNode? focusNode;
  final BardCollabConfig? collabConfig;

  const NoteState({
    this.note,
    this.bardController,
    this.focusNode,
    this.collabConfig,
  });

  NoteState copyWith({
    NoteArtifact? note,
    BardController? bardController,
    FocusNode? focusNode,
    BardCollabConfig? collabConfig,
  }) {
    return NoteState(
      note: note ?? this.note,
      bardController: bardController ?? this.bardController,
      focusNode: focusNode ?? this.focusNode,
      collabConfig: collabConfig ?? this.collabConfig,
    );
  }
}

class NoteNotifier extends AsyncNotifier<NoteState> {
  String? _vaultId;
  BardController? _controller;
  FocusNode? _focusNode;
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

    final snap = await snapsRepo.latestFor(note.id);
    if (!ref.mounted) return const NoteState();

    final initialOps = await opsRepo.opBytesFor(
      note.id,
      sinceSeq: snap?.maxOpSeq,
    );
    if (!ref.mounted) return const NoteState();

    // Fanout: we have to multiplex the realtime stream into something the
    // engine can subscribe to. We also use this same controller to forward
    // realtime ops the moment they arrive, with no echo filtering (CRDT
    // applyChange is idempotent on duplicate ids — own echoes are no-ops).
    final remoteOps = StreamController<Uint8List>.broadcast();
    _remoteOpsController = remoteOps;
    final supabaseSub = opsRepo.opByteStreamFor(note.id).listen(remoteOps.add);
    ref.onDispose(supabaseSub.cancel);

    final collab = BardCollabConfig(
      initialSnapshot: snap?.snapshotBytes,
      initialOps: initialOps,
      remoteOps: remoteOps.stream,
      onLocalOp: (bytes) {
        // Fire-and-forget; failures should surface via global error handling.
        opsRepo.append(note.id, bytes);
      },
    );

    final controller = BardController(text: '');
    _controller = controller;

    return NoteState(
      note: note,
      bardController: controller,
      focusNode: _focusNode,
      collabConfig: collab,
    );
  }

  // ===== FOCUS =====

  void setFocusNode(FocusNode focusNode) {
    _focusNode = focusNode;
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(focusNode: focusNode));
    }
  }

  bool get hasFocus => _focusNode?.hasFocus ?? false;
}

/// Type alias for note state providers — use in widget signatures.
typedef NoteStateProvider = AsyncNotifierProvider<NoteNotifier, NoteState>;

/// Creates a NoteNotifier for the currently selected Note item.
final selectedNoteStateProvider =
    AsyncNotifierProvider.autoDispose<NoteNotifier, NoteState>(
  NoteNotifier.new,
);
