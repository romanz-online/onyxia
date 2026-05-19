import 'package:onyxia/export.dart';

class ArtifactSnapshotsRepository
    extends BaseSupabaseRepository<ArtifactSnapshot> {
  ArtifactSnapshotsRepository({required super.vaultId});

  @override
  String get tableName => 'artifact_snapshots';

  @override
  String get scopeField => 'vault_id';

  @override
  List<String> get primaryKeyFields => const ['artifact_id'];

  @override
  ArtifactSnapshot fromMap(Map<String, dynamic> map) =>
      ArtifactSnapshot.fromMap(map);

  @override
  Map<String, dynamic> toMap(ArtifactSnapshot item) => item.toMap();

  @override
  String getIdFromItem(ArtifactSnapshot item) => item.artifactId;

  @override
  Map<String, dynamic> keyFilter(ArtifactSnapshot item) =>
      {'artifact_id': item.artifactId};

  /// Returns the latest snapshot for [artifactId], or null if none exists.
  Future<ArtifactSnapshot?> latestFor(String artifactId) async {
    if (vaultId == null || vaultId!.isEmpty) {
      throw ArgumentError('Invalid vaultId: $vaultId');
    }
    final row = await Supabase.instance.client
        .from(tableName)
        .select()
        .eq('artifact_id', artifactId)
        .maybeSingle();
    return row == null ? null : ArtifactSnapshot.fromMap(row);
  }
}
