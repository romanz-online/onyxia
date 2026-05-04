import 'package:onyxia/export.dart';

class ProjectSettingsButton extends ConsumerStatefulWidget {
  const ProjectSettingsButton({super.key});

  @override
  ConsumerState createState() => _ProjectSettingsButtonState();
}

class _ProjectSettingsButtonState extends ConsumerState<ProjectSettingsButton> {
  late Project activeProject;

  @override
  Widget build(BuildContext context) {
    activeProject = ref.read(projectsProvider).selectedProject;

    if (activeProject.id.isEmpty) return const SizedBox.shrink();

    final currentId = GoRouterState.of(context).pathParameters['selectedId'];
    final isOnSettings = currentId == Routes.settings;

    return NarwhalIconButton(
      icon: NarwhalIcons.settingsGear,
      onPressed: () {
        if (isOnSettings) {
          context.go('/project/${activeProject.id}/graph');
        } else {
          context.go('/project/${activeProject.id}/${Routes.settings}');
        }
      },
    );
  }
}
