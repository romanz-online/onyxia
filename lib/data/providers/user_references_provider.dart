import 'package:onyxia/export.dart';

final userReferencesProvider = StreamProvider.autoDispose
    .family<List<UserReference>, String?>((ref, explicitProjectId) {
  final projectId = (explicitProjectId != null && explicitProjectId.isNotEmpty)
      ? explicitProjectId
      : ref.watch(projectsProvider.select((s) => s.selectedProject.id));
  if (projectId.isEmpty) return Stream.value([]);
  return UserReferencesRepository(projectId: projectId).getStream();
});
