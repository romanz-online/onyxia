import 'package:onyxia/export.dart';
import 'note/note_editor_view.dart';
import 'image/image_editor_view.dart';

class ArtifactWorkspace extends ConsumerStatefulWidget {
  const ArtifactWorkspace({super.key});

  @override
  ConsumerState<ArtifactWorkspace> createState() => _ArtifactWorkspaceState();
}

class _ArtifactWorkspaceState extends ConsumerState<ArtifactWorkspace> {
  Widget _buildEditorContent(Artifact artifact) => switch (artifact.type) {
    .note => NoteEditorView(),
    .canvas => CanvasEditorView(canvasId: artifact.id),
    .folder => const SizedBox.shrink(),
    .image => ImageEditorView(artifact: artifact as ImageArtifact),
  };

  AppBar _buildAppBar(String title) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ThemeHelper.background1(),
      surfaceTintColor: ThemeHelper.background1(),
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 32,
      title: Center(
        child: Text(
          title,
          style: TextStyle(fontSize: 14, color: ThemeHelper.foreground1()),
        ),
      ),
    );
  }

  Widget _buildBody(Artifact selectedItem, AsyncValue noteAsyncState) {
    if (selectedItem.type == ArtifactType.note) {
      if (noteAsyncState.isLoading) {
        return Center(child: OnyxiaLoadingIndicator());
      }
      if (noteAsyncState.hasError) {
        return Center(
          child: Text(
            'Error: ${noteAsyncState.error}',
            style: TextStyle(color: ThemeHelper.foreground1()),
          ),
        );
      }
    }
    return _buildEditorContent(selectedItem);
  }

  @override
  Widget build(BuildContext context) {
    // Always subscribe to note state for save tracking
    final noteAsyncState = ref.watch(selectedNoteStateProvider);
    final rawSelectedItem = ref.watch(selectedArtifactProvider);
    final Artifact? selectedItem =
        rawSelectedItem ?? noteAsyncState.value?.note;

    if (selectedItem == null) {
      return Container(
        color: ThemeHelper.background1(),
        child: Center(
          child: Column(
            mainAxisAlignment: .center,
            spacing: 8,
            children: [
              Text(
                'No item selected',
                style: TextStyle(
                  fontStyle: .normal,
                  fontSize: 20,
                  // TODO: not here specifically but this and a lot of other pieces of text and icons (the master sidebar, the artifacts header, the artifact names in the tree view, the settings button) should be slightly dimmer at neutral500 (the same color the trailing extension text uses) instead of being this bright, which should be somewhat reserved for the editor, selected artifact in the tree, onyxiamenu items and a few other things
                  color: ThemeHelper.foreground1(),
                ),
              ),
              // TODO: this should have an inline-text hyperlink button to create a new untitled note
              Text(
                'Select an item from the sidebar to view',
                style: TextStyle(
                  fontStyle: .normal,
                  fontSize: 20,
                  color: ThemeHelper.foreground1(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(32),
            child: _buildAppBar(selectedItem.name),
          ),
          backgroundColor: ThemeHelper.background1(),
          body: SizedBox.expand(
            child: _buildBody(selectedItem, noteAsyncState),
          ),
        ),
      ],
    );
  }
}
