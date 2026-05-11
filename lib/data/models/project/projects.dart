import 'package:onyxia/export.dart';

class Projects {
  final List<Project> projects;
  final Project selectedProject;
  final bool isLoading;

  Projects({
    required this.projects,
    required this.selectedProject,
    this.isLoading = false,
  });

  factory Projects.initial() {
    return Projects(
      projects: [],
      selectedProject: Project.initial(),
      isLoading: true,
    );
  }

  Projects copyWith({
    List<Project>? projects,
    Project? selectedProject,
    bool? isLoading,
  }) {
    return Projects(
      projects: projects ?? this.projects,
      selectedProject: selectedProject ?? this.selectedProject,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() =>
      'Projects(projects: $projects, selectedProject: $selectedProject)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Projects &&
        listEquals(other.projects, projects) &&
        other.selectedProject == selectedProject;
  }

  @override
  int get hashCode => projects.hashCode ^ selectedProject.hashCode;
}
