import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/export.dart';
import 'dart:async';

const _100ms = Duration(milliseconds: 100);

class NoteState {
  final NoteArtifact? note;
  final BardController? bardController;
  final FocusNode? focusNode;
  final bool isSavedRemotely;

  const NoteState({
    this.note,
    this.bardController,
    this.focusNode,
    this.isSavedRemotely = false,
  });

  NoteState copyWith({
    NoteArtifact? note,
    BardController? bardController,
    FocusNode? focusNode,
    bool? isSavedRemotely,
  }) {
    return NoteState(
      note: note ?? this.note,
      bardController: bardController ?? this.bardController,
      focusNode: focusNode ?? this.focusNode,
      isSavedRemotely: isSavedRemotely ?? this.isSavedRemotely,
    );
  }
}

class NoteNotifier extends Notifier<AsyncValue<NoteState>> {
  String? _projectId;
  late NoteArtifact _note;
  BardController? _controller;
  VoidCallback? _controllerListener;
  FocusNode? _focusNode;
  Timer? _debounceTimer;
  StreamSubscription<Artifact?>? _docSub;

  @override
  AsyncValue<NoteState> build() {
    final selectedNoteId = ref.watch(
      selectedArtifactProvider.select((a) => a is NoteArtifact ? a.id : null),
    );
    _projectId =
        ref.watch(selectedProjectProvider.select((p) => p?.id));
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
      _note = NoteArtifact();
      return const AsyncValue.data(NoteState());
    }

    _note = ref.read(selectedArtifactProvider) as NoteArtifact;
    _initialize();
    return const AsyncValue.loading();
  }

  // ===== SETUP =====

  Future<void> _initialize() async {
    final repo = ArtifactsRepository(projectId: _projectId);
    final latestNote =
        await repo.getDocumentStream(_note.id).first as NoteArtifact? ?? _note;
    final myUserId = ref.read(currentUserProvider).value?.id;

    if (!ref.mounted) return;

    final controller = BardController(text: latestNote.content);

    // If the notifier was disposed (or rebuilt) while we were awaiting the
    // document, drop the just-created controller and bail â€” touching state
    // here would mutate a disposed notifier.
    if (!ref.mounted) {
      controller.dispose();
      return;
    }

    listener() {
      final current = state.value;
      if (current == null || current.note == null) return;
      final updatedNote = current.note!.copyWith(content: controller.text);
      state = AsyncData(
          current.copyWith(note: updatedNote, isSavedRemotely: false));
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
    _docSub = repo.getDocumentStream(_note.id).skip(1).listen((incoming) {
      if (incoming is! NoteArtifact) return;
      if (myUserId != null && incoming.updatedBy == myUserId) return;
      if (_debounceTimer?.isActive ?? false) return;
      final current = state.value;
      if (current == null) return;
      if (controller.text == incoming.content) {
        if (current.note != incoming) {
          state = AsyncData(
              current.copyWith(note: incoming, isSavedRemotely: true));
        }
        return;
      }
      controller.removeListener(listener);
      controller.text = incoming.content;
      controller.addListener(listener);
      state =
          AsyncData(current.copyWith(note: incoming, isSavedRemotely: true));
    });

    state = AsyncValue.data(NoteState(
      note: latestNote,
      bardController: controller,
      focusNode: _focusNode,
      isSavedRemotely: true,
    ));
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
    state = AsyncData(current.copyWith(
      note: current.note!.copyWith(name: title),
      isSavedRemotely: false,
    ));
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

    // After the await, state may have advanced (a keystroke landed during the
    // round-trip). Only flip the saved flag if nothing has changed locally —
    // otherwise leave isSavedRemotely=false so the next debounce tick saves
    // the newer content.
    final after = state.value;
    if (after == null || after.note == null) return;
    if (after.note!.content == outgoing.content &&
        after.note!.name == outgoing.name) {
      state = AsyncData(after.copyWith(isSavedRemotely: true));
    }
  }

  Future<void> saveDocumentWithHistory(WidgetRef widgetRef) async {
    final current = state.value;
    if (current == null || current.note == null) return;

    await _saveDocument();
  }

  void resetChanges() {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(isSavedRemotely: true));
    }
  }
}

/// Type alias for note state providers â€” use in widget signatures.
typedef NoteStateProvider
    = NotifierProvider<NoteNotifier, AsyncValue<NoteState>>;

/// Creates a NoteNotifier for the currently selected Note item.
final selectedNoteStateProvider =
    NotifierProvider.autoDispose<NoteNotifier, AsyncValue<NoteState>>(
  NoteNotifier.new,
);
