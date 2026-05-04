import 'package:onyxia/export.dart';

enum ProjectsShown {
  activeProjects,
  allProjects,
  removedProjects,
  publicProjects,
}

extension ProjectsShownExtension on ProjectsShown {
  String get value {
    switch (this) {
      case ProjectsShown.allProjects:
        return 'All Projects';
      case ProjectsShown.activeProjects:
        return 'Active Projects';
      case ProjectsShown.removedProjects:
        return 'Removed Projects';
      case ProjectsShown.publicProjects:
        return 'Public Projects';
    }
  }
}

class Projects {
  final List<Project> projects;
  final Project selectedProject;
  final ProjectsShown projectsShown;
  final String searchString;
  final bool isLoading;

  Projects({
    required this.projects,
    required this.selectedProject,
    required this.projectsShown,
    required this.searchString,
    this.isLoading = false,
  });

  factory Projects.initial() {
    return Projects(
      projects: [],
      selectedProject: Project.initial(),
      projectsShown: ProjectsShown.activeProjects,
      searchString: '',
      isLoading: true, // Start in loading state
    );
  }

  Projects copyWith({
    List<Project>? projects,
    Project? selectedProject,
    ProjectsShown? projectsShown,
    String? searchString,
    bool? isLoading,
  }) {
    return Projects(
      projects: projects ?? this.projects,
      selectedProject: selectedProject ?? this.selectedProject,
      projectsShown: projectsShown ?? this.projectsShown,
      searchString: searchString ?? this.searchString,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projects': projects.map((x) => x.toMap()).toList(),
      'selectedProject': selectedProject.toMap(),
      'projectsShown': projectsShown.toString().split('.').last,
      'searchString': searchString,
      'isLoading': isLoading,
    };
  }

  factory Projects.fromMap(Map<String, dynamic> map) {
    return Projects(
      projects: List<Project>.from(map['projects']?.map((x) => Project.fromMap(x))),
      selectedProject: Project.fromMap(map['selectedProject']),
      projectsShown: ProjectsShown.values.firstWhere((e) => e.toString().split('.').last == map['projectsShown']),
      searchString: map['searchString'],
      isLoading: map['isLoading'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Projects.fromJson(String source) => Projects.fromMap(json.decode(source));

  @override
  String toString() => 'Projects(projects: $projects, selectedProject: $selectedProject)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Projects && listEquals(other.projects, projects) && other.selectedProject == selectedProject;
  }

  @override
  int get hashCode => projects.hashCode ^ selectedProject.hashCode;
}
