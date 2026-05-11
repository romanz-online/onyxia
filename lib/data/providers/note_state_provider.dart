import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/export.dart';

const _500ms = Duration(milliseconds: 500);
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

class NoteNotifier extends StateNotifier<AsyncValue<NoteState>> {
  final String? projectId;
  final NoteArtifact _note;
  final Ref ref;

  bool _mounted = true;
  BardController? _controller;
  FocusNode? _focusNode;
  Timer? _debounceTimer;

  NoteNotifier(
      {required this.projectId, required NoteArtifact note, required this.ref})
      : _note = note,
        super(const AsyncValue.loading()) {
    if (projectId == null) {
      state = const AsyncValue.data(NoteState());
      return;
    }
    _initialize();
  }

  // ===== SETUP =====

  Future<void> _initialize() async {
    try {
      final latestNote = await ArtifactsRepository(projectId: projectId)
              .getDocumentStream(_note.id)
              .first as NoteArtifact? ??
          _note;

      final controller = BardController(text: latestNote.content);
      _controller = controller;

      controller.addListener(() {
        if (!_mounted) return;
        final current = state.value;
        if (current == null || current.note == null) return;
        final updatedNote = current.note!.copyWith(content: controller.text);
        state = AsyncData(
            current.copyWith(note: updatedNote, isSavedRemotely: false));
        if (ref.read(editorSaveModeProvider) == SaveMode.auto) {
          _debounceSave();
        }
      });

      if (_mounted) {
        state = AsyncValue.data(NoteState(
          note: latestNote,
          bardController: controller,
          focusNode: _focusNode,
          isSavedRemotely: true,
        ));
      }
    } catch (e, stack) {
      if (_mounted) state = AsyncValue.error(e, stack);
    }
  }

  // ===== FOCUS =====

  void setFocusNode(FocusNode focusNode) {
    if (!_mounted) return;
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
    if (ref.read(editorSaveModeProvider) == SaveMode.auto) {
      _debounceSave(duration: _100ms);
    }
  }

  // ===== SAVE =====

  void _debounceSave({Duration duration = _500ms}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, () {
      if (_mounted) _saveDocument();
    });
  }

  Future<void> _saveDocument() async {
    if (!_mounted) return;
    final current = state.value;
    if (current == null || current.note == null) return;

    await ArtifactsRepository(projectId: projectId).update(current.note!);

    if (_mounted) {
      state = AsyncData(current.copyWith(isSavedRemotely: true));
    }
  }

  Future<void> saveDocumentWithHistory(WidgetRef widgetRef) async {
    if (!_mounted) return;
    final current = state.value;
    if (current == null || current.note == null) return;

    await _saveDocument();
  }

  void resetChanges() {
    if (!_mounted) return;
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(isSavedRemotely: true));
    }
  }

  // ===== DISPOSAL =====

  @override
  void dispose() {
    _mounted = false;
    _debounceTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}

/// Type alias for note state providers — use in widget signatures.
typedef NoteStateProvider
    = AutoDisposeStateNotifierProvider<NoteNotifier, AsyncValue<NoteState>>;

/// Creates a NoteNotifier for the currently selected Note item.
final selectedNoteStateProvider =
    StateNotifierProvider.autoDispose<NoteNotifier, AsyncValue<NoteState>>(
        (ref) {
  final item = ref.watch(selectedArtifactProvider);
  final projectId =
      ref.watch(projectsProvider.select((s) => s.selectedProject?.id));
  final authState = ref.watch(authProvider);

  if (item is! NoteArtifact || projectId == null || authState.value == null) {
    return NoteNotifier(projectId: projectId, note: NoteArtifact(), ref: ref);
  }

  return NoteNotifier(projectId: projectId, note: item, ref: ref);
});
