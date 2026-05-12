import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/export.dart';
import 'dart:async';

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

class NoteNotifier extends Notifier<AsyncValue<NoteState>> {
  String? _projectId;
  late NoteArtifact _note;
  BardController? _controller;
  FocusNode? _focusNode;
  Timer? _debounceTimer;

  @override
  AsyncValue<NoteState> build() {
    final item = ref.watch(selectedArtifactProvider);
    _projectId =
        ref.watch(projectsProvider.select((s) => s.selectedProject?.id));
    final authState = ref.watch(authProvider);

    ref.onDispose(() {
      _debounceTimer?.cancel();
      _controller?.dispose();
    });

    if (item is! NoteArtifact ||
        _projectId == null ||
        authState.value == null) {
      _note = NoteArtifact();
      return const AsyncValue.data(NoteState());
    }

    _note = item;
    _initialize();
    return const AsyncValue.loading();
  }

  // ===== SETUP =====

  Future<void> _initialize() async {
    final latestNote = await ArtifactsRepository(projectId: _projectId)
            .getDocumentStream(_note.id)
            .first as NoteArtifact? ??
        _note;

    final controller = BardController(text: latestNote.content);
    _controller = controller;

    controller.addListener(() {
      final current = state.value;
      if (current == null || current.note == null) return;
      final updatedNote = current.note!.copyWith(content: controller.text);
      state = AsyncData(
          current.copyWith(note: updatedNote, isSavedRemotely: false));
      if (ref.read(editorSaveModeProvider) == SaveMode.auto) {
        _debounceSave();
      }
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
    if (ref.read(editorSaveModeProvider) == SaveMode.auto) {
      _debounceSave(duration: _100ms);
    }
  }

  // ===== SAVE =====

  void _debounceSave({Duration duration = _500ms}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, _saveDocument);
  }

  Future<void> _saveDocument() async {
    final current = state.value;
    if (current == null || current.note == null) return;

    await ArtifactsRepository(projectId: _projectId).update(current.note!);

    state = AsyncData(current.copyWith(isSavedRemotely: true));
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

/// Type alias for note state providers — use in widget signatures.
typedef NoteStateProvider
    = NotifierProvider<NoteNotifier, AsyncValue<NoteState>>;

/// Creates a NoteNotifier for the currently selected Note item.
final selectedNoteStateProvider =
    NotifierProvider.autoDispose<NoteNotifier, AsyncValue<NoteState>>(
  NoteNotifier.new,
);
