import 'package:onyxia/export.dart';
import 'note/note_editor_view.dart';
import 'image/image_editor_view.dart';

// TODO: there's too much loading flickering happening.
// TODO: cont. even if i can't load the content of the artifact immediately,
// TODO: cont. i should be able to at least load the artifact title immediately
// TODO: cont. which would significantly reduce the jarring lack of transition

class ArtifactWorkspace extends ConsumerStatefulWidget {
  final NoteStateProvider? noteProvider;

  const ArtifactWorkspace({super.key, this.noteProvider});

  @override
  ConsumerState<ArtifactWorkspace> createState() => _ArtifactWorkspaceState();
}

class _ArtifactWorkspaceState extends ConsumerState<ArtifactWorkspace> {
  NoteStateProvider get _noteProvider =>
      widget.noteProvider ?? selectedNoteStateProvider;

  Widget _buildEditorContent(Artifact artifact) {
    return switch (artifact.type) {
      ArtifactType.note => NoteEditorView(
          key: ValueKey('note-${artifact.id}'),
          provider: widget.noteProvider,
        ),
      ArtifactType.canvas => CanvasEditorView(canvasId: artifact.id),
      ArtifactType.folder => const SizedBox.shrink(),
      ArtifactType.image =>
        ImageEditorView(artifact: artifact as ImageArtifact),
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
    // Always subscribe to note state for save tracking
    final noteAsyncState = ref.watch(_noteProvider);

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
                style: NarwhalTextStyle(
                  fontStyle: FontStyle.normal,
                  fontSize: 20,
                ),
              ),
              Text(
                'Select an item from the sidebar to view',
                style: NarwhalTextStyle(
                  fontStyle: FontStyle.normal,
                  fontSize: 20,
                ),
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
      ],
    );
  }
}
