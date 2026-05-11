import 'package:onyxia/export.dart';

class ArtifactsRepository extends BaseSupabaseRepository<Artifact> {
  ArtifactsRepository({required super.projectId});

  @override
  String get tableName => 'artifacts';

  @override
  String get scopeField => 'project_id';

  @override
  String get defaultOrderBy => 'created_at';

  @override
  Artifact fromMap(Map<String, dynamic> map) => Artifact.factory(map);

  @override
  Map<String, dynamic> toMap(Artifact item) => item.toMap();

  @override
  String getIdFromItem(Artifact item) => item.id;

  Stream<List<CanvasModel>> getCanvasesStream() =>
      _streamByType<CanvasModel>(ArtifactType.canvas);

  Stream<List<T>> _streamByType<T extends Artifact>(ArtifactType type) {
    // Base scopes by project_id; post-filter by Dart type.
    return getStream().map((items) => items.whereType<T>().toList());
  }
}
