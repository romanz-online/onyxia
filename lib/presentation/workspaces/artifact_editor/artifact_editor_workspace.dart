import 'package:onyxia/export.dart';
import 'note/note_editor_view.dart';
import 'image/image_editor_view.dart';

class ArtifactWorkspace extends ConsumerStatefulWidget {
  const ArtifactWorkspace({super.key});

  @override
  ConsumerState<ArtifactWorkspace> createState() => _ArtifactWorkspaceState();
}

class _ArtifactWorkspaceState extends ConsumerState<ArtifactWorkspace> {
  bool _creatingNote = false;

  Future<void> _createUntitledNote() async {
    if (_creatingNote) return;
    final vaultId = ref.read(selectedVaultProvider)?.id;
    if (vaultId == null) return;
    setState(() => _creatingNote = true);
    final created = await ArtifactsRepository(
      vaultId: vaultId,
    ).add([NoteArtifact()]);
    if (!mounted) return;
    final saved = created.first;
    context.go(UrlHelper.artifactPath(vaultId: vaultId, name: saved.name));
  }

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
              if (_creatingNote)
                const OnyxiaLoadingIndicator()
              else
                // TODO: after the note is finished being made, there's a brief moment where the "no item selected" text reappears before the url and selection changes. i assume because of a rebuild here that shouldn't be happening. on release it's optimized enough that it isn't visible but i should fix it anyway.
                Column(
                  spacing: 12,
                  children: [
                    Text(
                      'No item selected',
                      style: TextStyle(
                        fontSize: 20,
                        color: ThemeHelper.foreground2(),
                      ),
                      textAlign: .center,
                    ),
                    HoverBuilder(
                      builder: (context, isHovered) {
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _createUntitledNote,
                            child: Text(
                              'Create new note',
                              style: TextStyle(
                                fontSize: 20,
                                color: Color.lerp(
                                  ThemeHelper.accent(),
                                  Colors.white,
                                  isHovered ? 0.3 : 0.0,
                                ),
                                decoration: TextDecoration.underline,
                                decorationColor: Color.lerp(
                                  ThemeHelper.accent(),
                                  Colors.white,
                                  isHovered ? 0.3 : 0.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              // TODO: also need some instructions on how to open the artifact search, which currently isn't implemented
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
