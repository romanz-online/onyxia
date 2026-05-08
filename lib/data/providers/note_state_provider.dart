import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/export.dart';

const _500ms = Duration(milliseconds: 500);
const _100ms = Duration(milliseconds: 100);

class NoteState {
  final Note? note;
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
    Note? note,
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
  final String projectId;
  final Note _note;
  final Ref ref;

  bool _mounted = true;
  BardController? _controller;
  FocusNode? _focusNode;
  Timer? _debounceTimer;

  NoteNotifier({required this.projectId, required Note note, required this.ref})
      : _note = note,
        super(const AsyncValue.loading()) {
    if (projectId.isEmpty) {
      state = const AsyncValue.data(NoteState());
      return;
    }
    _initialize();
  }

  // ===== SETUP =====

  Future<void> _initialize() async {
    try {
      final latestNote =
          await ArtifactsRepository(projectId: projectId).getDocumentStream(_note.title).first as Note? ?? _note;

      final controller = BardController(text: latestNote.content);
      _controller = controller;

      controller.addListener(() {
        if (!_mounted) return;
        final current = state.value;
        if (current == null || current.note == null) return;
        final updatedNote = current.note!.copyWith(content: controller.text);
        state = AsyncData(current.copyWith(note: updatedNote, isSavedRemotely: false));
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
      note: current.note!.copyWith(title: title),
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

    final serializer = NoteSerializerService(
      projectId: projectId,
      itemId: _note.title,
      repository: ArtifactsRepository(projectId: projectId),
    );

    if (HistoryService.pipeActive) {
      await _saveDocument();
    } else {
      await HistoryService.pipe(
        ref: widgetRef,
        projectId: projectId,
        operation: _saveDocument,
        serializer: serializer,
      );
    }
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
typedef NoteStateProvider = AutoDisposeStateNotifierProvider<NoteNotifier, AsyncValue<NoteState>>;

/// Creates a NoteNotifier for the currently selected Note item.
final selectedNoteStateProvider = StateNotifierProvider.autoDispose<NoteNotifier, AsyncValue<NoteState>>((ref) {
  final item = ref.watch(selectedArtifactProvider);
  final projectId = ref.watch(projectsProvider.select((s) => s.selectedProject.id));
  final authState = ref.watch(authProvider);

  if (item is! Note || projectId.isEmpty || authState.value == null) {
    return NoteNotifier(projectId: '', note: Note(), ref: ref);
  }

  return NoteNotifier(projectId: projectId, note: item, ref: ref);
});

/// Creates a NoteNotifier for the folder child preview panel.
final selectedFolderChildNoteStateProvider =
    StateNotifierProvider.autoDispose<NoteNotifier, AsyncValue<NoteState>>((ref) {
  final item = ref.watch(selectedFolderChildArtifactProvider);
  final projectId = ref.watch(projectsProvider.select((s) => s.selectedProject.id));
  final authState = ref.watch(authProvider);

  if (item is! Note || projectId.isEmpty || authState.value == null) {
    return NoteNotifier(projectId: '', note: Note(), ref: ref);
  }

  return NoteNotifier(projectId: projectId, note: item, ref: ref);
});
