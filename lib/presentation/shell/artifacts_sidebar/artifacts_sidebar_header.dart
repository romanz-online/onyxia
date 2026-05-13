import 'package:onyxia/export.dart';

class ArtifactsSidebarHeader extends ConsumerWidget {
  const ArtifactsSidebarHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProject = ref.watch(selectedProjectProvider);
    if (selectedProject == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ThemeHelper.neutral300(context), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 4,
        children: [
          NarwhalIconButton(
            icon: NarwhalIcons.addNew,
            tooltip: 'New note',
            onPressed: () async {
              await ArtifactsRepository(projectId: selectedProject.id)
                  .add([NoteArtifact()]);
            },
          ),
          NarwhalIconButton(
            icon: NarwhalIcons.folderClosed,
            tooltip: 'New folder',
            onPressed: () async {
              await ArtifactsRepository(projectId: selectedProject.id)
                  .add([FolderArtifact()]);
            },
          ),
          NarwhalIconButton(
            icon: NarwhalIcons.whiteboard,
            tooltip: 'New canvas',
            onPressed: () async {
              await ArtifactsRepository(projectId: selectedProject.id)
                  .add([CanvasArtifact()]);
            },
          ),
        ],
      ),
    );
  }
}
