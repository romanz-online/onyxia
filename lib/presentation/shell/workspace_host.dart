import 'package:onyxia/export.dart';

class WorkspaceHost extends StatelessWidget {
  final String projectId;
  final String? selectedId;

  const WorkspaceHost({
    super.key,
    required this.projectId,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    if (projectId.isEmpty) return const LandingBackground();
    if (selectedId == Routes.graph) return const GraphWorkspace();
    if (selectedId == Routes.settings) return const ProjectSettingsWorkspace();
    return const ArtifactWorkspace();
  }
}
