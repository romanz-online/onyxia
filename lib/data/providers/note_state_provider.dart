import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/export.dart';
import 'dart:async';

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

  @override
  Future<NoteState> build() async {
    final selectedNoteId = ref.watch(
      selectedArtifactProvider.select((a) => a is NoteArtifact ? a.id : null),
    );
    _projectId = ref.watch(selectedProjectProvider.select((p) => p?.id));
    final authState = ref.watch(authProvider);

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

    if (selectedNoteId == null ||
        _projectId == null ||
        authState.value == null) {
      return const NoteState();
    }

    final note = ref.read(selectedArtifactProvider) as NoteArtifact;
    final repo = ArtifactsRepository(projectId: _projectId);
    final latestNote =
        await repo.getDocumentStream(note.id).first as NoteArtifact? ?? note;
    final myUserId = ref.read(currentUserProvider).value?.id;

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

    // Live remote-edit sync: the server stamps `updated_by` with the writer's
    // auth UID, so any emission where it matches our own UID is the echo of
    // one of our saves and we skip it. Genuine remote edits (different user)
    // are applied — but deferred if the local user is mid-burst so we don't
    // yank text from under them.
    _docSub = repo.getDocumentStream(note.id).skip(1).listen((incoming) {
      if (incoming is! NoteArtifact) return;
      if (myUserId != null && incoming.updatedBy == myUserId) return;
      if (_debounceTimer?.isActive ?? false) return;
      final current = state.value;
      if (current == null) return;
      if (controller.text == incoming.content) {
        if (current.note != incoming) {
          state = AsyncData(current.copyWith(note: incoming));
        }
        return;
      }
      controller.removeListener(listener);
      controller.text = incoming.content;
      controller.addListener(listener);
      state = AsyncData(current.copyWith(note: incoming));
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

  // ===== TITLE UPDATE =====

  void updateTitle(String title) {
    final current = state.value;
    if (current == null || current.note == null) return;
    final updatedNote = current.note!.copyWith(name: title);
    state = AsyncData(current.copyWith(note: updatedNote));
    // Propagate optimistically to artifactsProvider so selectedArtifactProvider's
    // name-based lookup resolves immediately when the URL flips to the new name.
    // updateItemState only mutates the local list — the debounced _saveDocument
    // below handles repo persistence.
    ref.read(artifactsProvider.notifier).updateItemState(updatedNote);
    _debounceSave(duration: _100ms);
  }

  // ===== SAVE =====

  void _debounceSave({Duration duration = _100ms}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, _saveDocument);
  }

  Future<void> _saveDocument() async {
    final captured = state.value;
    if (captured == null || captured.note == null) return;
    final outgoing = captured.note!;
    await ArtifactsRepository(projectId: _projectId).update(outgoing);
  }
}

/// Type alias for note state providers — use in widget signatures.
typedef NoteStateProvider = AsyncNotifierProvider<NoteNotifier, NoteState>;

/// Creates a NoteNotifier for the currently selected Note item.
final selectedNoteStateProvider =
    AsyncNotifierProvider.autoDispose<NoteNotifier, NoteState>(
  NoteNotifier.new,
);
