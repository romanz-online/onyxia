import 'dart:convert';

import 'package:onyxia/export.dart';

class ArtifactOpsRepository extends BaseSupabaseRepository<ArtifactOp> {
  ArtifactOpsRepository({required super.vaultId});

  @override
  String get tableName => 'artifact_ops';

  @override
  String get scopeField => 'vault_id';

  @override
  String get defaultOrderBy => 'op_seq';

  @override
  ArtifactOp fromMap(Map<String, dynamic> map) => ArtifactOp.fromMap(map);

  @override
  Map<String, dynamic> toMap(ArtifactOp item) => item.toMap();

  @override
  String getIdFromItem(ArtifactOp item) => item.id;

  /// One-shot fetch of ops for a given artifact. Pass [sinceSeq] to skip ops
  /// already covered by a snapshot.
  Future<List<Uint8List>> opBytesFor(
    String artifactId, {
    int? sinceSeq,
  }) async {
    final ops = await query(
      field: 'artifact_id',
      isEqualTo: artifactId,
      orderBy: 'op_seq',
    );
    final filtered = sinceSeq == null
        ? ops
        : ops.where((o) => (o.opSeq ?? 0) > sinceSeq);
    return filtered.map((o) => o.opBytes).toList(growable: false);
  }

  /// Realtime stream of op bytes for a given artifact. Emits every op insert
  /// (initial backfill + subsequent realtime events) ordered by op_seq.
  Stream<Uint8List> opByteStreamFor(String artifactId) {
    return queryStream(
      field: 'artifact_id',
      isEqualTo: artifactId,
      orderBy: 'op_seq',
    ).expand((ops) => ops.map((o) => o.opBytes));
  }

  /// Appends a single CRDT op. Server assigns `op_seq`, `created_at`, and
  /// `user_id` (via `DEFAULT auth.uid()`).
  Future<void> append(String artifactId, Uint8List opBytes) async {
    if (vaultId == null || vaultId!.isEmpty) {
      throw ArgumentError('Invalid vaultId: $vaultId');
    }
    await Supabase.instance.client.from(tableName).insert({
      'artifact_id': artifactId,
      'vault_id': vaultId,
      'op_bytes': base64Encode(opBytes),
    });
  }
}
