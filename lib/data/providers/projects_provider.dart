import 'package:onyxia/export.dart';

final projectsProvider =
    NotifierProvider.autoDispose<ProjectsNotifier, Projects>(
  ProjectsNotifier.new,
);

class ProjectsNotifier extends Notifier<Projects> {
  final ProjectsRepository _repository = ProjectsRepository();

  @override
  Projects build() {
    ref.watch(authProvider);
    ref.watch(currentUserProvider);
    _loadProjects();
    return Projects.initial();
  }

  Future<void> _loadProjects() async {
    final projects = await _repository.getAll();
    state = state.copyWith(
      projects: projects,
      selectedProject: null,
      isLoading: false,
    );
  }

  void selectProject(Project project) {
    state = state.copyWith(selectedProject: project);
  }

  Future<void> selectProjectById(String projectId) async {
    final projectIndex = state.projects.indexWhere((p) => p.id == projectId);

    if (projectIndex != -1) {
      final project = state.projects[projectIndex];
      state = state.copyWith(selectedProject: project);
    } else {
      final project = await _repository.get(projectId);
      if (project != null) {
        final updatedProjects = [...state.projects, project];
        state = state.copyWith(
          projects: updatedProjects,
          selectedProject: project,
        );
      }
    }
  }

  void addProject(Project project) {
    state = state.copyWith(projects: [...state.projects, project]);
    _repository.add([project]);
  }

  void deleteProject(String id) {
    _repository.delete(id);
    state = state.copyWith(
        projects: state.projects.where((e) => e.id != id).toList());
  }

  void renameProject(String id, String newName) {
    final updatedProjects = state.projects.map((project) {
      if (project.id == id) {
        final updatedProject = project.copyWith(name: newName);
        _repository.update(updatedProject);
        return updatedProject;
      }
      return project;
    }).toList();

    state = state.copyWith(projects: updatedProjects);
  }

  void updateSelectedProject(Project updatedProject) {
    final updatedProjects = state.projects.map((project) {
      if (project.id == updatedProject.id) return updatedProject;
      return project;
    }).toList();

    state = state.copyWith(
      projects: updatedProjects,
      selectedProject: updatedProject,
    );

    _repository.update(updatedProject);
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
          text: 'User with email $email not found',
          type: ToastType.error,
        );
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

  void clearSelectedProject() {
    state = state.copyWith(clearSelectedProject: true);
  }
}
