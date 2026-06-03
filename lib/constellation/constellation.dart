import 'package:onyxia/export.dart';
import 'package:onyxia/bard/bard.dart';
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

ConstellationNode _nodeFromItem(BuildContext context, Artifact i) =>
    ConstellationNode(id: i.name);

typedef ConstellationLayout = ({
  List<ConstellationNode> nodes,
  List<ConstellationEdge> edges,
  Map<String, dynamic> forces,
});

/// Wiki-link layout: edges follow [[Title]] references in note content.
/// Filters drop file artifacts, orphan nodes, and zombie targets per user prefs.
ConstellationLayout _buildWikiLinks(
  BuildContext context,
  List<Artifact> items, {
  required bool showFiles,
  required bool showOrphans,
  required bool showZombies,
}) {
  final titleLookup = <String, String>{
    for (final i in items) i.name.toLowerCase(): i.name,
  };

  var nodes = items.map((i) => _nodeFromItem(context, i)).toList();
  final edges = <ConstellationEdge>[];
  final zombieNames = <String>{};

  for (final item in items) {
    if (item is! NoteArtifact) continue;
    // TODO: because this uses item.content, it misses content updates until the notes' ops are compressed. eventually this should actually read through the ops to properly see what up-to-date connections there are
    for (final rawLink in extractWikiLinks(item.content)) {
      final canonical = titleLookup[rawLink.toLowerCase()];
      if (canonical != null && canonical != item.name) {
        edges.add(ConstellationEdge(source: item.name, target: canonical));
      } else if (canonical == null && rawLink.isNotEmpty) {
        zombieNames.add(rawLink);
        edges.add(ConstellationEdge(source: item.name, target: rawLink));
      }
    }
  }

  if (showZombies) {
    nodes.addAll(zombieNames.map((n) => ConstellationNode(id: n)));
  }

  if (!showFiles) {
    nodes = nodes.where((n) => !_isFileName(n.id)).toList();
  }

  final keptIds = nodes.map((n) => n.id).toSet();
  var keptEdges = edges
      .where((e) => keptIds.contains(e.source) && keptIds.contains(e.target))
      .toList();

  if (!showZombies) {
    keptEdges = keptEdges
        .where((e) => !zombieNames.contains(e.target))
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
  bool _showOrphans = false;
  bool _showZombies = false;

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
    if (!async.hasValue) return Center(child: OnyxiaLoadingIndicator());
    final items = async.value!;

    final layout = _buildWikiLinks(
      context,
      items,
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
