import 'package:onyxia/export.dart';

final projectsProvider =
    StateNotifierProvider.autoDispose<ProjectsNotifier, Projects>((ref) {
  final authState = ref.watch(authProvider);
  final userState = ref.watch(currentUserProvider);

  if (authState.value == null || userState.id.isEmpty) {
    return ProjectsNotifier(Projects.initial(), ProjectsRepository(), '');
  }

  return ProjectsNotifier(
      Projects.initial(), ProjectsRepository(), userState.id);
});

class ProjectsNotifier extends StateNotifier<Projects> {
  final ProjectsRepository projectsRepository;
  final String currentUserId;

  ProjectsNotifier(
    super.state,
    this.projectsRepository,
    this.currentUserId,
  ) {
    if (currentUserId.isNotEmpty) {
      _loadProjects();
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await projectsRepository.getProjects(currentUserId);

      if (!mounted) return;

      state = state.copyWith(
          projects: projects,
          selectedProject: Project.initial(),
          isLoading: false);
    } catch (e) {
      if (!mounted) return;
      print('_loadProjects $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void selectProject(Project project) {
    state = state.copyWith(selectedProject: project);
  }

  Future<void> selectProjectById(String projectId) async {
    if (!mounted) return;

    final projectIndex = state.projects.indexWhere((p) => p.id == projectId);

    if (projectIndex != -1) {
      final project = state.projects[projectIndex];
      state = state.copyWith(selectedProject: project);
    } else {
      try {
        final project = await projectsRepository.get(projectId);

        if (project != null && mounted) {
          if (project.ownerId == currentUserId) {
            final updatedProjects = [...state.projects, project];
            state = state.copyWith(
              projects: updatedProjects,
              selectedProject: project,
            );
          }
        }
      } catch (e) {
        debugPrint('Failed to load project $projectId: $e');
      }
    }
  }

  void addProject(Project project) {
    state = state.copyWith(projects: [...state.projects, project]);
    projectsRepository.add([project]);
  }

  void deleteProject(String id) {
    projectsRepository.delete(id);
    state = state.copyWith(
        projects: state.projects.where((e) => e.id != id).toList());
  }

  void renameProject(String id, String newName) {
    final updatedProjects = state.projects.map((project) {
      if (project.id == id) {
        final updatedProject = project.copyWith(name: newName);
        projectsRepository.update(updatedProject);
        return updatedProject;
      }
      return project;
    }).toList();

    state = state.copyWith(projects: updatedProjects);
  }

  void setProjectsShown(ProjectsShown type) {
    state = state.copyWith(projectsShown: type);
  }

  void setSearchString(String searchString) {
    state = state.copyWith(searchString: searchString);
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

    projectsRepository.update(updatedProject);
  }

  Future<void> removeMember({
    required String projectId,
    required UserReference member,
  }) async {
    try {
      await UserReferencesRepository(projectId: projectId).delete(member);
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
      final user =
          await UserDefinitionsRepository(projectId: 'root').getByEmail(email);

      if (user == null) {
        NarwhalToast.show(
          text: 'User with email $email not found',
          type: ToastType.error,
        );
        return;
      }

      await UserReferencesRepository(projectId: projectId)
          .add([UserReference(definitionId: user.id, role: role)]);
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
    state = state.copyWith(selectedProject: Project.initial());
  }
}
