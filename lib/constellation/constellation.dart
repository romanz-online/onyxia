import 'package:onyxia/export.dart';
import 'package:onyxia/constellation/constellation_simulation.dart';
import 'package:onyxia/constellation/constellation_renderer.dart';

final RegExp _fileExtensionPattern = RegExp(
  r'\.[a-z0-9]{1,5}$',
  caseSensitive: false,
);
bool _isFileName(String name) => _fileExtensionPattern.hasMatch(name);

const _defaultForces = {
  'repelStrength': 1000,
  'linkDistance': 180,
  'linkStrength': 1,
  'centerStrength': 0.1,
};

typedef ConstellationLayout = ({
  List<ConstellationNode> nodes,
  List<ConstellationEdge> edges,
  Map<String, dynamic> forces,
});

/// Wiki-link layout: edges follow [[Title]] references in note content.
/// Filters drop file artifacts, orphan nodes, and zombie targets per user prefs.
/// Pure filtering over the cached [WikiGraph] — extraction happens once in
/// [wikiGraphProvider], so toggling filters here never re-parses note content.
ConstellationLayout _buildWikiLinks(
  WikiGraph graph, {
  required bool showFiles,
  required bool showOrphans,
  required bool showZombies,
}) {
  var nodes = graph.nodeNames.map((n) => ConstellationNode(id: n)).toList();

  if (showZombies) {
    nodes.addAll(graph.zombieNames.map((n) => ConstellationNode(id: n)));
  }

  if (!showFiles) {
    nodes = nodes.where((n) => !_isFileName(n.id)).toList();
  }

  final keptIds = nodes.map((n) => n.id).toSet();
  var keptEdges = graph.edges
      .where((e) => keptIds.contains(e.source) && keptIds.contains(e.target))
      .map((e) => ConstellationEdge(source: e.source, target: e.target))
      .toList();

  if (!showZombies) {
    keptEdges = keptEdges
        .where((e) => !graph.zombieNames.contains(e.target))
        .toList();
  }

  if (!showOrphans) {
    final connectedIds = <String>{};
    for (final e in keptEdges) {
      connectedIds.add(e.source);
      connectedIds.add(e.target);
    }
    nodes = nodes.where((n) => connectedIds.contains(n.id)).toList();
    final finalIds = nodes.map((n) => n.id).toSet();
    keptEdges = keptEdges
        .where(
          (e) => finalIds.contains(e.source) && finalIds.contains(e.target),
        )
        .toList();
  }

  return (nodes: nodes, edges: keptEdges, forces: _defaultForces);
}

class Constellation extends ConsumerStatefulWidget {
  const Constellation({super.key});

  @override
  ConsumerState<Constellation> createState() => _ConstellationState();
}

class _ConstellationState extends ConsumerState<Constellation> {
  bool _filterMenuOpen = false;
  bool _showFiles = false;
  bool _showOrphans = true;
  bool _showZombies = true;

  void _onNodeTap(String nodeId) {
    final item = (ref.read(artifactsProvider).value ?? const <Artifact>[])
        .firstWhereOrNull((e) => e.name == nodeId);
    if (item == null) return;
    context.go(
      Routes.artifactUrl(
        vaultId: ref.read(selectedVaultProvider)?.id,
        name: item.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(artifactsProvider);
    if (!async.hasValue) return const Center(child: OnyxiaLoadingIndicator());
    final graph = ref.watch(wikiGraphProvider);

    final layout = _buildWikiLinks(
      graph,
      showFiles: _showFiles,
      showOrphans: _showOrphans,
      showZombies: _showZombies,
    );

    return Stack(
      children: [
        ConstellationRenderer(
          physicsNodes: layout.nodes,
          physicsEdges: layout.edges,
          visualEdges: layout.edges,
          forces: layout.forces,
          onNodeTap: _onNodeTap,
        ),
        Positioned(
          top: 12,
          right: 12,
          child: OnyxiaOverlay(
            isOpen: _filterMenuOpen,
            onClose: () => setState(() => _filterMenuOpen = false),
            builder: (context, closeOverlay) => OnyxiaCheckboxMenu(
              items: [
                OnyxiaCheckboxMenuItem(
                  label: 'Files',
                  checked: _showFiles,
                  onToggle: () => setState(() => _showFiles = !_showFiles),
                ),
                OnyxiaCheckboxMenuItem(
                  label: 'Orphans',
                  checked: _showOrphans,
                  onToggle: () => setState(() => _showOrphans = !_showOrphans),
                ),
                OnyxiaCheckboxMenuItem(
                  label: 'Zombies',
                  checked: _showZombies,
                  onToggle: () => setState(() => _showZombies = !_showZombies),
                ),
              ],
            ),
            child: OnyxiaIconButton(
              icon: LucideIcons.funnel,
              tooltip: 'Filter nodes',
              tooltipDirection: .left,
              isSelected: _filterMenuOpen,
              onPressed: () =>
                  setState(() => _filterMenuOpen = !_filterMenuOpen),
            ),
          ),
        ),
      ],
    );
  }
}
