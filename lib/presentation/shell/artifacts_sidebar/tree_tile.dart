import 'package:onyxia/export.dart';

class TreeTile extends ConsumerWidget {
  const TreeTile({super.key, required this.node, this.isDragging = false});

  final TreeNode<Artifact> node;
  final bool isDragging;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeData = ref.watch(
      artifactsProvider.select(
        (async) => (async.value ?? const <Artifact>[]).firstWhere(
          (n) => n.id == node.data.id,
          orElse: () => node.data,
        ),
      ),
    );

    return Container(
      height: 24,
      decoration: isDragging
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: ThemeHelper.white(context).withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: Padding(
        padding: .only(right: 12),
        child: EditableArtifactName(
          item: nodeData,
          trailingExtension: _imageExt(nodeData),
        ),
      ),
    );
  }

  String? _imageExt(Artifact a) {
    if (a is! ImageArtifact) return null;
    final dot = a.name.lastIndexOf('.');
    if (dot <= 0 || dot == a.name.length - 1) return null;
    return a.name.substring(dot + 1).toUpperCase();
  }
}
