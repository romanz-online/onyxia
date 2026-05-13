import 'package:onyxia/export.dart';

class ArtifactsSidebarFooter extends ConsumerWidget {
  const ArtifactsSidebarFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProject = ref.watch(selectedProjectProvider);
    final projectName = selectedProject == null || selectedProject.name.isEmpty
        ? 'Onyxia'
        : selectedProject.name;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ThemeHelper.neutral300(context), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          OnyxiaButton(
            label: projectName,
            onTap: () => context.go('/${Routes.projects}'),
          ),
          const Spacer(),
          if (selectedProject != null) const ProjectSettingsButton(),
        ],
      ),
    );
  }
}
