import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/canvas_engine/providers/providers.dart';
import 'note/note_editor_view.dart';

class ArtifactEditor extends ConsumerStatefulWidget {
  final SaveMode saveMode;
  final NoteStateProvider? noteProvider; 

  const ArtifactEditor({
    super.key,
    this.saveMode = SaveMode.auto,
    this.noteProvider,
  });

  @override
  ConsumerState<ArtifactEditor> createState() => _ArtifactEditorState();
}

class _ArtifactEditorState extends ConsumerState<ArtifactEditor> {
  bool _isSaving = false;
  bool _showNotifyBar = false;
  bool _bypassNotifyBar = false;
  DateTime? _notifySuppressedUntil;

  NoteStateProvider get _noteProvider =>
      widget.noteProvider ?? selectedNoteStateProvider;

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(_noteProvider.notifier);
      await notifier.saveDocumentWithHistory(ref);
      if (mounted) {
        setState(() {
          _isSaving = false;
          if (_notifySuppressedUntil == null ||
              DateTime.now().isAfter(_notifySuppressedUntil!)) {
            _showNotifyBar = true;
          }
        });
        NarwhalToast.show(text: 'Saved successfully', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      NarwhalToast.show(text: 'Failed to save: $e', type: ToastType.error);
    }
  }

  void _handleReset() {
    setState(() => _showNotifyBar = false);
    ref.invalidate(_noteProvider);
  }

  Widget _buildEditorContent(Artifact artifact) {
    return switch (artifact.type) {
      ArtifactType.note => NoteEditorView(
          key: ValueKey('note-${artifact.id}'),
          saveMode: widget.saveMode,
          provider: widget.noteProvider,
        ),
      ArtifactType.canvas => ref.read(urlCanvasIdProvider) == null
          ? CanvasEditorView(
              canvasId: artifact.id,
              saveMode: widget.saveMode,
            )
          : const SizedBox.shrink(),
      ArtifactType.folder => const SizedBox.shrink(),
    };
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ThemeHelper.neutral100(context),
      surfaceTintColor: ThemeHelper.neutral100(context),
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 32,
      title: Center(child: Text(title, style: NarwhalTextStyle(fontSize: 14))),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorSaveModeProvider.notifier).set(widget.saveMode);
    });

    // Always subscribe to note state for save tracking
    final noteAsyncState = ref.watch(_noteProvider);

    ref.listen(_noteProvider, (previous, next) {
      final prevSaved = previous?.value?.isSavedRemotely;
      final nextSaved = next.value?.isSavedRemotely;
      if (widget.saveMode == SaveMode.auto &&
          prevSaved == false &&
          nextSaved == true) {
        if (_bypassNotifyBar) {
          _bypassNotifyBar = false;
        } else if (_notifySuppressedUntil == null ||
            DateTime.now().isAfter(_notifySuppressedUntil!)) {
          setState(() => _showNotifyBar = true);
        }
      }
    });

    ref.listen(selectedArtifactProvider, (previous, next) {
      if (previous?.name != next?.name) {
        setState(() {
          _showNotifyBar = false;
          _notifySuppressedUntil = null;
        });
      }
    });

    // When a custom note provider is given, the item comes from it.
    // For notes with the global provider, prefer the live note state over the stale selectedArtifactProvider.
    // For non-note items (canvases, folders), selectedArtifactProvider is authoritative.
    final rawSelectedItem = ref.watch(selectedArtifactProvider);
    final Artifact? selectedItem = widget.noteProvider != null
        ? noteAsyncState.value?.note
        : (rawSelectedItem?.type == ArtifactType.note
            ? (noteAsyncState.value?.note ?? rawSelectedItem)
            : rawSelectedItem);

    if (selectedItem == null) {
      return Container(
        color: ThemeHelper.neutral100(context),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Text(
                'No item selected',
                style: NarwhalTextStyle.bodyLarge(fontStyle: FontStyle.normal),
              ),
              Text(
                'Select an item from the sidebar to view',
                style: NarwhalTextStyle.bodyLarge(fontStyle: FontStyle.normal),
              ),
            ],
          ),
        ),
      );
    }

    // Notes gate on the async note provider state
    if (selectedItem.type == ArtifactType.note) {
      if (noteAsyncState.isLoading) {
        return Container(
          color: ThemeHelper.neutral100(context),
          child: Center(child: NarwhalSpinner()),
        );
      }
      if (noteAsyncState.hasError) {
        return Container(
          color: ThemeHelper.neutral100(context),
          child: Center(
            child: Text(
              'Error: ${noteAsyncState.error}',
              style: NarwhalTextStyle(color: ThemeHelper.neutral700(context)),
            ),
          ),
        );
      }
    }

    final isSavedRemotely = selectedItem.type == ArtifactType.note
        ? (noteAsyncState.value?.isSavedRemotely ?? true)
        : true;

    return Stack(
      children: [
        Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(32),
            child: _buildAppBar(selectedItem.name),
          ),
          backgroundColor: ThemeHelper.neutral100(context),
          body: SizedBox.expand(child: _buildEditorContent(selectedItem)),
        ),
        if (widget.saveMode == SaveMode.manual &&
            !isSavedRemotely &&
            !_showNotifyBar)
          Align(
            alignment: Alignment.bottomCenter,
            child: SaveChangesBar(
              isSaving: _isSaving,
              onSave: _handleSave,
              onReset: _handleReset,
            ),
          ),
      ],
    );
  }
}
