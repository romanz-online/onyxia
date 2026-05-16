import 'package:onyxia/export.dart';

class WorkspaceHost extends StatelessWidget {
  final String vaultId;
  final String? selectedId;

  const WorkspaceHost({super.key, required this.vaultId, this.selectedId});

  @override
  Widget build(BuildContext context) {
    if (vaultId.isEmpty) return const LandingBackground();
    if (selectedId == Routes.graph) return const GraphWorkspace();
    return const ArtifactWorkspace();
  }
}
