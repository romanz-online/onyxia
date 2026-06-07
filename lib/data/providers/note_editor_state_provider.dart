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
  NoteArtifact? _note;
  NoteBroadcastSession? _session;
  StreamController<String>? _externalContentController;

  // Debounced writeback of the converged editor text into artifacts.body.content
  // — the canonical source of truth. CRDT ops are an ephemeral broadcast-only
  // transport; this writeback is what makes the text durable and is what other
  // clients reconcile against (see the externalContent backstop below).
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
      _externalContentController?.close();
      _externalContentController = null;
      _session?.dispose();
      _session = null;
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

    // Ephemeral live-sync over Supabase Realtime Broadcast. The session
    // subscribes immediately and buffers inbound ops until the engine attaches.
    final session = NoteBroadcastRepository(
      vaultId: _vaultId,
    ).openSession(note.id);
    _session = session;

    // Backstop: a remote body.content change that didn't arrive as live ops
    // (peer disconnected, wiki-link rename) is pushed here for the editor to
    // merge via Myers diff. Single-subscription stream consumed by the editor.
    final externalContent = StreamController<String>();
    _externalContentController = externalContent;

    final collab = BardCollabConfig(
      initialContent: note.content,
      remoteOps: session.inboundOps,
      onLocalOp: (bytes) {
        // Broadcast to peers, then schedule the canonical writeback.
        session.broadcastOp(bytes);
        _scheduleContentWriteback();
      },
      externalContent: externalContent.stream,
    );

    // Forward remote body.content updates into the live editor. selectedArtifact
    // tracks the realtime artifacts stream, so a content change from another
    // client surfaces here. Skip our own writeback echoes and anything the
    // editor already shows — only genuinely-newer remote text reaches the engine.
    ref.listen<String?>(
      selectedArtifactProvider.select(
        (a) => a is NoteArtifact && a.id == note.id ? a.content : null,
      ),
      (prev, next) {
        if (next == null) return;
        final controller = _controller;
        if (controller == null) return;
        if (next == controller.text) return; // editor already shows it
        if (next == _lastWrittenContent) return; // our own writeback echo
        _externalContentController?.add(next);
      },
    );

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
