import 'package:onyxia/export.dart';

final memberDefinitionsProvider =
    StateNotifierProvider<ProjectMembersNotifier, List<UserDefinition>>((ref) {
  return ProjectMembersNotifier(ref);
});

class ProjectMembersNotifier extends StateNotifier<List<UserDefinition>> {
  Set<String> _currentIds = {};

  ProjectMembersNotifier(Ref ref) : super([]) {
    ref.listen<AsyncValue<List<UserReference>>>(
      userReferencesProvider(null),
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

    if (removedIds.isNotEmpty) {
      final updated = state.where((u) => !removedIds.contains(u.id)).toList();
      if (mounted) {
        state = updated;
        AttributeDefinitionRegistry.register<UserDefinition>(updated);
      }
    }

    if (addedIds.isNotEmpty) {
      final repo = UserDefinitionsRepository();
      final fetched = await Future.wait(addedIds.map(repo.get));
      final newUsers = fetched.whereType<UserDefinition>().toList();
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
