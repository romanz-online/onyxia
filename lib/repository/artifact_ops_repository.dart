import 'package:onyxia/export.dart';
import 'dart:async';
import 'dart:convert';

// TODO: might need to make artifact ops automatically update the vault's and artifact's updatedAt in supabase

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
  Future<List<Uint8List>> opBytesFor(String artifactId, {int? sinceSeq}) async {
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

  /// Realtime stream of op bytes for a given artifact. Subscribes to
  /// INSERT-only Postgres changes filtered by `artifact_id` and emits each new
  /// op exactly once. Initial backfill is the caller's responsibility (use
  /// [opBytesFor] for that).
  ///
  /// `.stream()` was the wrong primitive here — it emits the full sorted
  /// result set on every change, which produced O(N²) apply attempts and
  /// magnified any pre-existing DB duplicates. `onPostgresChanges` gives us
  /// exactly-once INSERT delivery.
  Stream<Uint8List> opByteStreamFor(String artifactId) {
    late final RealtimeChannel channel;
    late final StreamController<Uint8List> controller;
    controller = StreamController<Uint8List>(
      onListen: () {
        channel =
            Supabase.instance.client
                .channel('artifact_ops:$artifactId')
                .onPostgresChanges(
                  event: .insert,
                  schema: 'public',
                  table: tableName,
                  filter: PostgresChangeFilter(
                    type: .eq,
                    column: 'artifact_id',
                    value: artifactId,
                  ),
                  callback: (payload) {
                    final encoded = payload.newRecord['op_bytes'] as String?;
                    if (encoded == null) return;
                    controller.add(base64Decode(encoded));
                  },
                )
              ..subscribe();
      },
      onCancel: () async {
        await Supabase.instance.client.removeChannel(channel);
      },
    );
    return controller.stream;
  }

  /// Highest `op_seq` recorded for [artifactId], or null if no ops exist.
  /// Used by snapshot-rebuild flows to cap a replacement snapshot's
  /// `max_op_seq` so the load path skips superseded ops.
  Future<int?> maxSeqFor(String artifactId) async {
    if (vaultId == null || vaultId!.isEmpty) {
      throw ArgumentError('Invalid vaultId: $vaultId');
    }
    final row = await Supabase.instance.client
        .from(tableName)
        .select('op_seq')
        .eq('artifact_id', artifactId)
        .order('op_seq', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : row['op_seq'] as int?;
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
