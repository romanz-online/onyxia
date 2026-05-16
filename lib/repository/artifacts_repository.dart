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

  /// Writes only the `body` column for a note. Keeps the live editor's
  /// debounced saves from clobbering concurrent metadata writes (rename,
  /// reparent) that touch `name`, `parent_folder_id`, etc.
  Future<void> updateNoteContent(String id, String content) async {
    if (vaultId == null || vaultId!.isEmpty) {
      throw ArgumentError('Invalid vaultId: $vaultId');
    }
    await Supabase.instance.client.from(tableName).update({
      'body': {'content': content}
    }).eq('id', id);
  }
}
