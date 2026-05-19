import 'package:onyxia/export.dart';

class ArtifactsRepository extends BaseSupabaseRepository<Artifact> {
  ArtifactsRepository({required super.vaultId});

  @override
  String get tableName => 'artifacts';

  @override
  String get scopeField => 'vault_id';

  @override
  String get defaultOrderBy => 'created_at';

  @override
  Artifact fromMap(Map<String, dynamic> map) => Artifact.factory(map);

  @override
  Map<String, dynamic> toMap(Artifact item) => item.toMap();

  @override
  String getIdFromItem(Artifact item) => item.id;
}
