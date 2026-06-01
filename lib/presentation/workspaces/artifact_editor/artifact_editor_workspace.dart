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
  Artifact? _pendingArtifact;

  static const double appBarHeight = 32;

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
    setState(() {
      _pendingArtifact = saved; // bridge the gap before providers catch up
      _creatingNote = false;
    });
    context.go(Routes.artifactUrl(vaultId: vaultId, name: saved.name));
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
      toolbarHeight: appBarHeight,
      title: Center(
        child: Text(
          title,
          style: TextStyle(fontSize: 14, color: ThemeHelper.foreground1()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always subscribe to note state for save tracking
    final rawSelectedItem = ref.watch(selectedArtifactProvider);

    // Clear pending once the provider has caught up
    if (_pendingArtifact != null &&
        rawSelectedItem?.id == _pendingArtifact!.id) {
      // Use a post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pendingArtifact = null);
      });
    }

    final Artifact? selectedItem = rawSelectedItem ?? _pendingArtifact;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(appBarHeight),
        child: SizedBox(
          height: appBarHeight,
          child: selectedItem != null ? _buildAppBar(selectedItem.name) : null,
        ),
      ),
      backgroundColor: ThemeHelper.background1(),
      body: selectedItem != null
          ? SizedBox.expand(child: _buildEditorContent(selectedItem))
          : Center(
              child: Column(
                mainAxisAlignment: .center,
                spacing: 8,
                children: [
                  if (_creatingNote)
                    const OnyxiaLoadingIndicator()
                  else
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
}
