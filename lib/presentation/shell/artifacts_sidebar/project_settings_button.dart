import 'package:onyxia/export.dart';

class ProjectSettingsButton extends ConsumerStatefulWidget {
  const ProjectSettingsButton({super.key});

  @override
  ConsumerState createState() => _ProjectSettingsButtonState();
}

class _ProjectSettingsButtonState extends ConsumerState<ProjectSettingsButton> {
  @override
  Widget build(BuildContext context) {
    final projectId = ref.read(selectedProjectProvider)?.id;

    if (projectId == null) return const SizedBox.shrink();

    final currentId = GoRouterState.of(context).pathParameters['selectedId'];
    final isOnSettings = currentId == Routes.settings;

    return NarwhalIconButton(
      icon: NarwhalIcons.settingsGear,
      onPressed: () {
        if (isOnSettings) {
          context.go('/project/$projectId/graph');
        } else {
          context.go('/project/$projectId/${Routes.settings}');
        }
      },
    );
  }
}
