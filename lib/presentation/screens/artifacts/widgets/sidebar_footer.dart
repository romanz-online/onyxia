import 'package:onyxia/export.dart';

class SidebarFooter extends ConsumerWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProject = ref.watch(projectsProvider).selectedProject;
    final projectName = selectedProject == null || selectedProject.name.isEmpty
        ? 'Onyxia'
        : selectedProject.name;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: ThemeHelper.neutral300(context), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          OnyxiaButton(
            label: projectName,
            onTap: () => context.go('/${Routes.projects}'),
          ),
          const Spacer(),
          const ProjectSettingsButton(),
        ],
      ),
    );
  }
}
