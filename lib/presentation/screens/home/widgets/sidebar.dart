import 'package:onyxia/export.dart';

class Sidebar extends ConsumerWidget {
  final String projectId;

  const Sidebar({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 42,
      height: double.infinity,
      decoration: BoxDecoration(
        color: ThemeHelper.neutral100(context),
        border: Border(
          right: BorderSide(color: ThemeHelper.neutral300(context), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (projectId.isNotEmpty) ...[
              NarwhalIconButton(
                icon: NarwhalIcons.dashboard,
                tooltip: 'Open graph',
                onPressed: () {
                  if (projectId.isEmpty) return;
                  context.go('/project/$projectId/${Routes.graph}');
                },
              ),
              NarwhalIconButton(
                icon: NarwhalIcons.addNew,
                tooltip: 'New note',
                onPressed: () async {
                  if (projectId.isEmpty) return;
                  await ArtifactsRepository(projectId: projectId)
                      .add(Note(), suppressStream: false);
                },
              ),
              NarwhalIconButton(
                icon: NarwhalIcons.folderClosed,
                tooltip: 'New folder',
                onPressed: () async {
                  if (projectId.isEmpty) return;
                  await ArtifactsRepository(projectId: projectId)
                      .add(FolderModel(), suppressStream: false);
                },
              ),
              NarwhalIconButton(
                icon: NarwhalIcons.whiteboard,
                tooltip: 'New canvas',
                onPressed: () async {
                  if (projectId.isEmpty) return;
                  await ArtifactsRepository(projectId: projectId)
                      .add(CanvasModel(), suppressStream: false);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
