import 'package:onyxia/export.dart';

class Projects {
  final List<Project> projects;
  final Project selectedProject;
  final String searchString;
  final bool isLoading;

  Projects({
    required this.projects,
    required this.selectedProject,
    required this.searchString,
    this.isLoading = false,
  });

  factory Projects.initial() {
    return Projects(
      projects: [],
      selectedProject: Project.initial(),
      searchString: '',
      isLoading: true, // Start in loading state
    );
  }

  Projects copyWith({
    List<Project>? projects,
    Project? selectedProject,
    String? searchString,
    bool? isLoading,
  }) {
    return Projects(
      projects: projects ?? this.projects,
      selectedProject: selectedProject ?? this.selectedProject,
      searchString: searchString ?? this.searchString,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projects': projects.map((x) => x.toMap()).toList(),
      'selectedProject': selectedProject.toMap(),
      'searchString': searchString,
      'isLoading': isLoading,
    };
  }

  factory Projects.fromMap(Map<String, dynamic> map) {
    return Projects(
      projects:
          List<Project>.from(map['projects']?.map((x) => Project.fromMap(x))),
      selectedProject: Project.fromMap(map['selectedProject']),
      searchString: map['searchString'],
      isLoading: map['isLoading'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Projects.fromJson(String source) =>
      Projects.fromMap(json.decode(source));

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
