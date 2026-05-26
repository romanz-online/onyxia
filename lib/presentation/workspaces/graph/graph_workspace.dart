import 'package:onyxia/constellation/constellation.dart';
import 'package:onyxia/export.dart';

class GraphWorkspace extends ConsumerStatefulWidget {
  const GraphWorkspace({super.key});

  @override
  ConsumerState<GraphWorkspace> createState() => _GraphWorkspaceState();
}

class _GraphWorkspaceState extends ConsumerState<GraphWorkspace> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeHelper.neutral100(context),
        borderRadius: .only(topLeft: .circular(8)),
      ),
      child: const Constellation(),
    );
  }
}
