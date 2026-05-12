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

    return NarwhalIconButton(
      icon: NarwhalIcons.settingsGear,
      onPressed: () {},
    );
  }
}
