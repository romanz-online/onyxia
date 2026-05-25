import 'package:onyxia/export.dart';
import 'note/note_editor_view.dart';
import 'image/image_editor_view.dart';

// TODO: renaming an artifact now correctly updates the URL but doesn't immediately update the loaded title text and links to that artifact aren't getting updated

class ArtifactWorkspace extends ConsumerStatefulWidget {
  const ArtifactWorkspace({super.key});

  @override
  ConsumerState<ArtifactWorkspace> createState() => _ArtifactWorkspaceState();
}

class _ArtifactWorkspaceState extends ConsumerState<ArtifactWorkspace> {
  Widget _buildEditorContent(Artifact artifact) {
    return switch (artifact.type) {
      ArtifactType.note => NoteEditorView(),
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

  Widget _buildBody(Artifact selectedItem, AsyncValue noteAsyncState) {
    if (selectedItem.type == ArtifactType.note) {
      if (noteAsyncState.isLoading) {
        return Center(child: NarwhalSpinner());
      }
      if (noteAsyncState.hasError) {
        return Center(
          child: Text(
            'Error: ${noteAsyncState.error}',
            style: NarwhalTextStyle(color: ThemeHelper.neutral700(context)),
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
        noteAsyncState.value?.note ?? rawSelectedItem;

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

    return Stack(
      children: [
        Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(32),
            child: _buildAppBar(selectedItem.name),
          ),
          backgroundColor: ThemeHelper.neutral100(context),
          body: SizedBox.expand(
            child: _buildBody(selectedItem, noteAsyncState),
          ),
        ),
      ],
    );
  }
}
