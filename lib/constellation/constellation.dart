import 'package:onyxia/export.dart';
import 'package:onyxia/bard/bard.dart';
import 'package:onyxia/constellation/constellation_simulation.dart';
import 'package:onyxia/constellation/constellation_renderer.dart';

// ── Force presets ─────────────────────────────────────────────────────────────

const _defaultForces = {
  'repelStrength': 1000,
  'linkDistance': 250,
  'linkStrength': 1,
  'centerStrength': 0.1,
};

ConstellationNode _nodeFromItem(BuildContext context, Artifact i) => ConstellationNode(id: i.title);

// ── Layout builders ───────────────────────────────────────────────────────────

typedef ConstellationLayout = ({
  List<ConstellationNode> nodes,
  List<ConstellationEdge> edges,
  Map<String, dynamic> forces,
});

/// Wiki-link layout: edges follow [[Title]] references in note content.
ConstellationLayout _buildWikiLinks(BuildContext context, List<Artifact> items) {
  final nodes = items.map((i) => _nodeFromItem(context, i)).toList();

  // Case-insensitive lookup: lowercased title → canonical title
  final titleLookup = <String, String>{
    for (final i in items) i.title.toLowerCase(): i.title,
  };

  final edges = <ConstellationEdge>[];
  for (final item in items) {
    if (item is! Note) continue;
    for (final rawLink in extractWikiLinks(item.content)) {
      final canonical = titleLookup[rawLink.toLowerCase()];
      if (canonical != null && canonical != item.title) {
        edges.add(ConstellationEdge(source: item.title, target: canonical));
      }
    }
  }

  return (nodes: nodes, edges: edges, forces: _defaultForces);
}

// ── Widget ────────────────────────────────────────────────────────────────────

class Constellation extends ConsumerStatefulWidget {
  const Constellation({super.key});

  @override
  ConsumerState<Constellation> createState() => _ConstellationState();
}

class _ConstellationState extends ConsumerState<Constellation> {
  void _onNodeTap(String nodeId) {
    final item = ref.read(artifactsProvider).firstWhereOrNull((e) => e.title == nodeId);
    if (item == null) return;
    ref.read(selectedArtifactProvider.notifier).state = item;
    final projectId = ref.read(projectsProvider).selectedProject.id;
    context.go(item.navigationUrl(projectId));
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(artifactsProvider);
    // this order is correct and important to accurately update the graph
    final isLoaded = ref.watch(artifactsLoadedProvider);
    if (!isLoaded) return Center(child: NarwhalSpinner());

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
