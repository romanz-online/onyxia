import 'package:onyxia/export.dart';
import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/constellation/constellation_simulation.dart';
import 'package:onyxia/constellation/constellation_renderer.dart';

// â”€â”€ Force presets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

const _defaultForces = {
  'repelStrength': 1000,
  'linkDistance': 250,
  'linkStrength': 1,
  'centerStrength': 0.1,
};

ConstellationNode _nodeFromItem(BuildContext context, Artifact i) =>
    ConstellationNode(id: i.name);

// â”€â”€ Layout builders â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

typedef ConstellationLayout = ({
  List<ConstellationNode> nodes,
  List<ConstellationEdge> edges,
  Map<String, dynamic> forces,
});

/// Wiki-link layout: edges follow [[Title]] references in note content.
ConstellationLayout _buildWikiLinks(
    BuildContext context, List<Artifact> items) {
  final nodes = items.map((i) => _nodeFromItem(context, i)).toList();

  // Case-insensitive lookup: lowercased title â†’ canonical title
  final titleLookup = <String, String>{
    for (final i in items) i.name.toLowerCase(): i.name,
  };

  final edges = <ConstellationEdge>[];
  for (final item in items) {
    if (item is! NoteArtifact) continue;
    for (final rawLink in extractWikiLinks(item.content)) {
      final canonical = titleLookup[rawLink.toLowerCase()];
      if (canonical != null && canonical != item.name) {
        edges.add(ConstellationEdge(source: item.name, target: canonical));
      }
    }
  }

  return (nodes: nodes, edges: edges, forces: _defaultForces);
}

// â”€â”€ Widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class Constellation extends ConsumerStatefulWidget {
  const Constellation({super.key});

  @override
  ConsumerState<Constellation> createState() => _ConstellationState();
}

class _ConstellationState extends ConsumerState<Constellation> {
  void _onNodeTap(String nodeId) {
    final item = (ref.read(artifactsProvider).value ?? const <Artifact>[])
        .firstWhereOrNull((e) => e.name == nodeId);
    if (item == null) return;
    final projectId = ref.read(selectedProjectProvider)?.id;
    context.go(item.navigationUrl(projectId ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(artifactsProvider);
    if (!async.hasValue) return Center(child: NarwhalSpinner());
    final items = async.value!;

    final layout = _buildWikiLinks(context, items);

    return Stack(
      children: [
        ConstellationRenderer(
          physicsNodes: layout.nodes,
          physicsEdges: layout.edges,
          visualEdges: layout.edges,
          forces: layout.forces,
          onNodeTap: _onNodeTap,
        ),
      ],
    );
  }
}
