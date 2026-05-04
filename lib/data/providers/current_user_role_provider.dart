import 'package:onyxia/export.dart';

/// The current logged-in user's role in the currently selected project.
/// Returns null if the user is not a member of the selected project
/// or if no project is selected.
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final userId = ref.watch(currentUserProvider.select((u) => u.id));
  final members = ref.watch(
    projectMembersProvider(null).select((async) => async.asData?.value ?? []),
  );
  return members.firstWhereOrNull((m) => m.definitionId == userId)?.role;
});
