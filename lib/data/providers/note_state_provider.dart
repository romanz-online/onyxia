import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/export.dart';
import 'dart:async';
import 'dart:collection';

const _100ms = Duration(milliseconds: 100);

class NoteState {
  final NoteArtifact? note;
  final BardController? bardController;
  final FocusNode? focusNode;

  const NoteState({
    this.note,
    this.bardController,
    this.focusNode,
  });

  NoteState copyWith({
    NoteArtifact? note,
    BardController? bardController,
    FocusNode? focusNode,
  }) {
    return NoteState(
      note: note ?? this.note,
      bardController: bardController ?? this.bardController,
      focusNode: focusNode ?? this.focusNode,
    );
  }
}

class NoteNotifier extends AsyncNotifier<NoteState> {
  String? _projectId;
  BardController? _controller;
  VoidCallback? _controllerListener;
  FocusNode? _focusNode;
  Timer? _debounceTimer;
  StreamSubscription<Artifact?>? _docSub;
  // FIFO of contents we've sent to the DB. Each echo from the document
  // stream pops the head if it matches — that's our own save. Echoes that
  // don't match are external (remote user, or a programmatic write like
  // rename) and get applied to the live controller.
  final Queue<String> _pendingEchoContents = Queue<String>();

  @override
  Future<NoteState> build() async {
    final selectedNoteId = ref.watch(
      selectedArtifactProvider.select((a) => a is NoteArtifact ? a.id : null),
    );
    _projectId = ref.watch(selectedProjectProvider.select((p) => p?.id));

    ref.onDispose(() {
      _debounceTimer?.cancel();
      _docSub?.cancel();
      _docSub = null;
      final controller = _controller;
      final listener = _controllerListener;
      _controller = null;
      _controllerListener = null;
      if (controller != null) {
        // Detach our own listener synchronously so it can't fire on a
        // disposed notifier between now and the deferred dispose below.
        if (listener != null) controller.removeListener(listener);
        // Defer dispose to the next frame so consumer widgets (BardEditor)
        // can detach their own listeners on a still-live controller during
        // their dispose() / didUpdateWidget().
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.dispose();
        });
      }
    });

    if (selectedNoteId == null || _projectId == null) {
      return const NoteState();
    }

    final note = ref.read(selectedArtifactProvider) as NoteArtifact;
    final repo = ArtifactsRepository(projectId: _projectId);
    final latestNote =
        await repo.getDocumentStream(note.id).first as NoteArtifact? ?? note;

    // If deps changed during the await, abort cleanly so we don't allocate a
    // controller that escapes onDispose's reach.
    if (!ref.mounted) return const NoteState();

    final controller = BardController(text: latestNote.content);

    listener() {
      final current = state.value;
      if (current == null || current.note == null) return;
      final updatedNote = current.note!.copyWith(content: controller.text);
      state = AsyncData(current.copyWith(note: updatedNote));
      _debounceSave();
    }

    _controller = controller;
    _controllerListener = listener;
    controller.addListener(listener);

    // Live document sync. Own-save echoes are identified by FIFO content
    // match against _pendingEchoContents — Supabase realtime delivers events
    // in commit order, so the order our saves go out is the order their
    // echoes come back. Anything that doesn't match the queue head is
    // external (remote user, or our own non-typing write like rename) and
    // gets pushed into the live controller.
    _docSub = repo.getDocumentStream(note.id).skip(1).listen((incoming) {
      if (incoming is! NoteArtifact) return;
      final current = state.value;
      if (current == null) return;

      if (_pendingEchoContents.isNotEmpty &&
          _pendingEchoContents.first == incoming.content) {
        _pendingEchoContents.removeFirst();
        if (current.note != incoming) {
          state = AsyncData(current.copyWith(note: incoming));
        }
        return;
      }

      // External update. Don't yank text mid-burst — defer to the next echo
      // cycle after the user pauses.
      if (_debounceTimer?.isActive ?? false) return;

      if (controller.text != incoming.content) {
        controller.removeListener(listener);
        controller.text = incoming.content;
        controller.addListener(listener);
      }
      if (current.note != incoming) {
        state = AsyncData(current.copyWith(note: incoming));
      }
    });

    return NoteState(
      note: latestNote,
      bardController: controller,
      focusNode: _focusNode,
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

  // ===== SAVE =====

  void _debounceSave({Duration duration = _100ms}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, _saveDocument);
  }

  Future<void> _saveDocument() async {
    final captured = state.value;
    if (captured == null || captured.note == null) return;
    final outgoing = captured.note!;
    _pendingEchoContents.add(outgoing.content);
    await ArtifactsRepository(projectId: _projectId).update([outgoing]);
  }
}

/// Type alias for note state providers — use in widget signatures.
typedef NoteStateProvider = AsyncNotifierProvider<NoteNotifier, NoteState>;

/// Creates a NoteNotifier for the currently selected Note item.
final selectedNoteStateProvider =
    AsyncNotifierProvider.autoDispose<NoteNotifier, NoteState>(
  NoteNotifier.new,
);
