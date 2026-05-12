import 'package:onyxia/export.dart';

final projectMembersProvider = StreamProvider.autoDispose
    .family<List<ProjectMember>, String?>((ref, explicitProjectId) {
  final projectId = (explicitProjectId != null && explicitProjectId.isNotEmpty)
      ? explicitProjectId
      : ref.watch(selectedProjectProvider.select((p) => p?.id));
  if (projectId == null) return Stream.value([]);
  return ProjectMembersRepository(projectId: projectId).getStream();
});
