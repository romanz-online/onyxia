import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onyxia/export.dart';

class ProjectsRepository extends BaseFirestoreRepository<Project> {
  final String? userId;

  ProjectsRepository({this.userId}) : super(projectId: 'root');

  @override
  String get collectionPath => 'projects';

  @override
  Project fromMap(Map<String, dynamic> map) => Project.fromMap(map);

  @override
  Map<String, dynamic> toMap(Project item) => item.toMap();

  @override
  String getIdFromItem(Project item) => item.id;

  @override
  bool get updateProjectMetadata => false;

  /// Fetch all projects for a specific user.
  /// Admin users have access to all projects regardless of project membership.
  /// Regular users have access to projects they are members of OR that are marked as public.
  /// This method uses Firestore's query to filter projects based on the members subcollection and isPublic flag,
  /// or fetches all projects for admin users.
  /// It returns a list of Project objects.
  /// If an error occurs, it prints the error and returns an empty list.
  Future<List<Project>> getProjects(String userId) async {
    try {
      // Handle empty user ID case
      if (userId.isEmpty) return [];

      // First, get the user to check if they are an admin
      final user = await UserDefinitionsRepository(projectId: 'root').get(userId);

      if (user == null) return [];

      // Check if the user is an admin
      final isAdmin = AdminConfig.isAdminEmail(user.email);

      if (isAdmin) {
        // Admin users can see all projects
        final querySnapshot = await FirebaseFirestore.instance.collection(collectionPath).get();
        return querySnapshot.docs.map((doc) => Project.fromMap(doc.data())).toList();
      } else {
        final Map<String, Project> projectsMap = {};

        final memberSnapshot =
            await FirebaseFirestore.instance.collectionGroup('members').where('definitionId', isEqualTo: userId).get();

        final projectIds = memberSnapshot.docs.map((doc) => doc.reference.parent.parent!.id).toSet();

        final projectFutures = projectIds.map(
          (id) => FirebaseFirestore.instance.collection(collectionPath).doc(id).get(),
        );
        final projectDocs = await Future.wait(projectFutures);
        for (final doc in projectDocs) {
          if (doc.exists) {
            final project = Project.fromMap(doc.data()!);
            projectsMap[project.id] = project;
          }
        }

        final publicProjectsSnapshot = await FirebaseFirestore.instance
            .collection(collectionPath)
            .where(
              'isPublic',
              isEqualTo: true,
            )
            .get();

        for (final doc in publicProjectsSnapshot.docs) {
          final project = Project.fromMap(doc.data());
          projectsMap[project.id] = project;
        }

        return projectsMap.values.toList();
      }
    } catch (e) {
      debugPrint('Error fetching projects: $e');
      return [];
    }
  }
}
