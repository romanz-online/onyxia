import 'package:onyxia/export.dart';
import 'package:onyxia/constellation/constellation_renderer.dart';
import 'package:onyxia/constellation/constellation_simulation.dart';

const _worldbuildingForces = {
  'repelStrength': 800,
  'linkDistance': 180,
  'linkStrength': 0.8,
  'centerStrength': 0.1,
};

const _nodes = [
  ConstellationNode(id: 'welcome'),
  ConstellationNode(id: 'to'),
  ConstellationNode(id: 'onyxia'),
  ConstellationNode(id: 'character'),
  ConstellationNode(id: 'plot'),
  ConstellationNode(id: 'language'),
  ConstellationNode(id: 'setting'),
  ConstellationNode(id: 'conflict'),
  ConstellationNode(id: 'theme'),
  ConstellationNode(id: 'culture'),
  ConstellationNode(id: 'history'),
  ConstellationNode(id: 'motive'),
  ConstellationNode(id: 'imagery'),
  ConstellationNode(id: 'relationships'),
];

const _edges = [
  ConstellationEdge(source: 'character', target: 'plot'),
  ConstellationEdge(source: 'character', target: 'conflict'),
  ConstellationEdge(source: 'character', target: 'motive'),
  ConstellationEdge(source: 'character', target: 'relationships'),
  ConstellationEdge(source: 'character', target: 'language'),
  ConstellationEdge(source: 'character', target: 'culture'),
  ConstellationEdge(source: 'plot', target: 'conflict'),
  ConstellationEdge(source: 'plot', target: 'theme'),
  ConstellationEdge(source: 'plot', target: 'history'),
  ConstellationEdge(source: 'plot', target: 'motive'),
  ConstellationEdge(source: 'plot', target: 'imagery'),
  ConstellationEdge(source: 'plot', target: 'relationships'),
  ConstellationEdge(source: 'language', target: 'culture'),
  ConstellationEdge(source: 'language', target: 'setting'),
  ConstellationEdge(source: 'setting', target: 'culture'),
  ConstellationEdge(source: 'setting', target: 'history'),
  ConstellationEdge(source: 'setting', target: 'plot'),
  ConstellationEdge(source: 'conflict', target: 'history'),
  ConstellationEdge(source: 'conflict', target: 'theme'),
  ConstellationEdge(source: 'conflict', target: 'relationships'),
  ConstellationEdge(source: 'theme', target: 'culture'),
  ConstellationEdge(source: 'theme', target: 'motive'),
  ConstellationEdge(source: 'theme', target: 'history'),
  ConstellationEdge(source: 'theme', target: 'relationships'),
  ConstellationEdge(source: 'theme', target: 'imagery'),
  ConstellationEdge(source: 'culture', target: 'history'),
  ConstellationEdge(source: 'culture', target: 'relationships'),
  ConstellationEdge(source: 'history', target: 'motive'),
  ConstellationEdge(source: 'motive', target: 'relationships'),
  ConstellationEdge(source: 'welcome', target: 'to'),
  ConstellationEdge(source: 'to', target: 'onyxia'),
];

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstellationRenderer(
      physicsNodes: _nodes,
      physicsEdges: _edges,
      visualEdges: _edges,
      forces: _worldbuildingForces,
      onNodeTap: (_) {},
    );
  }
}
