import 'package:onyxia/export.dart';
import 'package:onyxia/presentation/shell/artifacts_sidebar/editable_artifact_name.dart';

class TreeTile extends ConsumerWidget {
  const TreeTile({
    super.key,
    required this.node,
    this.isDragging = false,
  });

  final TreeNode<Artifact> node;
  final bool isDragging;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeData = ref.watch(
      artifactsProvider.select(
        (items) => items.firstWhere((n) => n.id == node.data.id, orElse: () => node.data),
      ),
    );

    return Container(
      height: 24,
      decoration: isDragging
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: ThemeHelper.black(context).withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: EditableArtifactName(item: nodeData),
      ),
    );
  }
}
