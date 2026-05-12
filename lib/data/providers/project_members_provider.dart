import 'package:onyxia/export.dart';

final projectMembersProvider =
    StreamProvider.autoDispose<List<ProjectMember>>((ref) {
  final projectId = ref.watch(selectedProjectProvider.select((p) => p?.id));
  if (projectId == null) return Stream.value([]);
  return ProjectMembersRepository(projectId: projectId).getStream();
});
