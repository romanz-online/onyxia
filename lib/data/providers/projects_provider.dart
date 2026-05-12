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

  Future<void> removeMember({
    required String projectId,
    required ProjectMember member,
  }) async {
    try {
      await ProjectMembersRepository(projectId: projectId).delete(member);
      NarwhalToast.show(text: 'Member removed', type: ToastType.success);
    } catch (e) {
      NarwhalToast.show(text: 'Error removing member', type: ToastType.error);
    }
  }

  Future<void> addMemberByEmail({
    required String projectId,
    required String email,
    required UserRole role,
  }) async {
    try {
      final user = await UsersRepository().getByEmail(email);

      if (user == null) {
        NarwhalToast.show(
            text: 'User with email $email not found', type: ToastType.error);
        return;
      }

      await ProjectMembersRepository(projectId: projectId).add([
        ProjectMember(projectId: projectId, userId: user.id, role: role),
      ]);
      NarwhalToast.show(
        text: 'User with email $email added successfully',
        type: ToastType.success,
      );
    } catch (e) {
      debugPrint('Error adding member by email: $e');
      NarwhalToast.show(text: 'Error: $e', type: ToastType.error);
    }
  }
}
