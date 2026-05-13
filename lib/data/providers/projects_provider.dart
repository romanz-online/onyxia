import 'package:onyxia/export.dart';

final projectsProvider =
    StreamNotifierProvider<ProjectsNotifier, List<Project>>(
  ProjectsNotifier.new,
);

class ProjectsNotifier extends StreamNotifier<List<Project>> {
  final ProjectsRepository _repository = ProjectsRepository();

  @override
  Stream<List<Project>> build() {
    ref.watch(authProvider);
    ref.watch(currentUserProvider);
    return _repository.getStream();
  }

  void addProject(Project project) => _repository.add([project]);

  void deleteProject(String id) => _repository.delete(id);

  void renameProject(String id, String newName) {
    final p = state.value?.firstWhereOrNull((e) => e.id == id);
    if (p == null) return;
    _repository.update(p.copyWith(name: newName));
  }
}
