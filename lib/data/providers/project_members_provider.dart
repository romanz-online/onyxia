import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onyxia/export.dart';

final memberDefinitionsProvider =
    StateNotifierProvider<ProjectMembersNotifier, List<UserDefinition>>((ref) {
  return ProjectMembersNotifier(ref);
});

class ProjectMembersNotifier extends StateNotifier<List<UserDefinition>> {
  Set<String> _currentIds = {};

  ProjectMembersNotifier(Ref ref) : super([]) {
    ref.listen<AsyncValue<List<UserReference>>>(
      projectMembersProvider(null),
      (_, next) {
        final newIds = next.asData?.value.map((m) => m.definitionId).toSet() ??
            const <String>{};
        if (!setEquals(newIds, _currentIds)) {
          _applyDiff(newIds);
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> _applyDiff(Set<String> newIds) async {
    final addedIds = newIds.difference(_currentIds);
    final removedIds = _currentIds.difference(newIds);
    _currentIds = newIds;

    // Remove departed members immediately — no Firestore read needed
    if (removedIds.isNotEmpty) {
      final updated = state.where((u) => !removedIds.contains(u.id)).toList();
      if (mounted) {
        state = updated;
        AttributeDefinitionRegistry.register<UserDefinition>(updated);
      }
    }

    // Fetch only the newly added member(s)
    if (addedIds.isNotEmpty) {
      final docs = await Future.wait(
        addedIds.map((id) =>
            FirebaseFirestore.instance.collection('users').doc(id).get()),
      );
      final newUsers = docs
          .where((d) => d.exists)
          .map((d) => UserDefinition.fromMap({...d.data()!, 'id': d.id}))
          .toList();
      if (mounted) {
        final updated = [...state, ...newUsers];
        state = updated;
        AttributeDefinitionRegistry.register<UserDefinition>(updated);
      }
    }
  }

  @override
  void dispose() {
    AttributeDefinitionRegistry.clear<UserDefinition>();
    super.dispose();
  }
}
