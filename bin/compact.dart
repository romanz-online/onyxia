/// Scheduled CRDT compaction worker.
///
/// For each artifact with enough unfolded ops, loads the latest snapshot,
/// replays subsequent ops through `crdt_lf`, writes a new pruned snapshot,
/// and deletes ops that are both folded and older than the grace period.
///
/// Connects to Postgres via the standard wire protocol so it is independent
/// of any specific managed-database vendor. Reads the connection string from
/// the DATABASE_URL environment variable.
///
/// Run: `DATABASE_URL=postgresql://... dart run bin/compact.dart`
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crdt_lf/crdt_lf.dart';
import 'package:postgres/postgres.dart';

const _unfoldedOpThreshold = 25;
const _unfoldedAgeHours = 24;

Future<void> main() async {
  final dbUrl = Platform.environment['DATABASE_URL'];
  if (dbUrl == null || dbUrl.isEmpty) {
    stderr.writeln('DATABASE_URL environment variable is required.');
    exit(1);
  }

  final conn = await Connection.open(
    _parseEndpoint(dbUrl),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  try {
    final candidates = await _findArtifactsNeedingCompaction(conn);
    stdout
        .writeln('Found ${candidates.length} artifact(s) needing compaction.');

    var compacted = 0;
    var skipped = 0;
    for (final c in candidates) {
      final didWork = await _compactArtifact(
        conn,
        artifactId: c.artifactId,
        vaultId: c.vaultId,
      );
      if (didWork) {
        compacted++;
      } else {
        skipped++;
      }
    }
    stdout.writeln('Done. compacted=$compacted skipped=$skipped');

    await _cleanupExpiredInvitations(conn);
  } finally {
    await conn.close();
  }
}

Future<void> _cleanupExpiredInvitations(Connection conn) async {
  final result = await conn.execute(Sql.named('''
    DELETE FROM vault_invitations
    WHERE expires_at < NOW()
  '''));
  stdout.writeln('Deleted ${result.affectedRows} expired invitation(s).');
}

Endpoint _parseEndpoint(String url) {
  final uri = Uri.parse(url);
  if (uri.scheme != 'postgresql' && uri.scheme != 'postgres') {
    throw FormatException(
        'DATABASE_URL must start with postgresql:// or postgres://');
  }
  final userInfo = uri.userInfo.split(':');
  if (userInfo.length < 2) {
    throw const FormatException('DATABASE_URL must include username:password');
  }
  return Endpoint(
    host: uri.host,
    port: uri.port == 0 ? 5432 : uri.port,
    database: uri.pathSegments.isEmpty ? 'postgres' : uri.pathSegments.last,
    username: Uri.decodeComponent(userInfo[0]),
    password: Uri.decodeComponent(userInfo.sublist(1).join(':')),
  );
}

class _Candidate {
  _Candidate(this.artifactId, this.vaultId);
  final String artifactId;
  final String vaultId;
}

Future<List<_Candidate>> _findArtifactsNeedingCompaction(
  Connection conn,
) async {
  final rows = await conn.execute(
    Sql.named('''
      SELECT o.artifact_id::text AS artifact_id, o.vault_id::text AS vault_id
      FROM artifact_ops o
      LEFT JOIN artifact_snapshots s ON s.artifact_id = o.artifact_id
      WHERE o.op_seq > COALESCE(s.max_op_seq, 0)
      GROUP BY o.artifact_id, o.vault_id
      HAVING COUNT(*) >= @threshold
          OR MIN(o.created_at) < NOW() - make_interval(hours => @ageHours)
    '''),
    parameters: {
      'threshold': _unfoldedOpThreshold,
      'ageHours': _unfoldedAgeHours,
    },
  );
  return [
    for (final row in rows) _Candidate(row[0]! as String, row[1]! as String),
  ];
}

Future<bool> _compactArtifact(
  Connection conn, {
  required String artifactId,
  required String vaultId,
}) {
  return conn.runTx<bool>((tx) async {
    await tx.execute(
      Sql.named('SELECT pg_advisory_xact_lock(hashtext(@aid))'),
      parameters: {'aid': artifactId},
    );

    Snapshot? priorSnap;
    var priorMaxOpSeq = 0;
    final snapResult = await tx.execute(
      Sql.named('''
        SELECT snapshot_bytes, max_op_seq
        FROM artifact_snapshots
        WHERE artifact_id = @aid::uuid
      '''),
      parameters: {'aid': artifactId},
    );
    if (snapResult.isNotEmpty) {
      final row = snapResult.first;
      priorSnap = _decodeSnapshot(base64Decode(row[0]! as String));
      priorMaxOpSeq = (row[1] as int?) ?? 0;
    }

    final opsResult = await tx.execute(
      Sql.named('''
        SELECT op_seq, op_bytes
        FROM artifact_ops
        WHERE artifact_id = @aid::uuid AND op_seq > @since
        ORDER BY op_seq ASC
      '''),
      parameters: {'aid': artifactId, 'since': priorMaxOpSeq},
    );
    if (opsResult.isEmpty) return false;

    final newMaxOpSeq = opsResult.last[0]! as int;
    final changes = [
      for (final row in opsResult)
        _decodeChange(base64Decode(row[1]! as String)),
    ];

    final doc = CRDTDocument(peerId: PeerId.generate());
    CRDTFugueTextHandler(doc, 'content');
    try {
      if (priorSnap != null) {
        doc.importSnapshot(priorSnap);
      }
      doc.importChanges(changes);
      final newSnap = doc.takeSnapshot(pruneHistory: true);
      final snapBytes = _encodeSnapshot(newSnap);
      final versionVectorJson = jsonEncode(newSnap.versionVector.toJson());

      final verifyDoc = CRDTDocument(peerId: PeerId.generate());
      final verifyText = CRDTFugueTextHandler(verifyDoc, 'content');
      verifyDoc.importSnapshot(_decodeSnapshot(snapBytes));
      final expectedLen = (newSnap.data['content'] as List).length;
      if (verifyText.value.isEmpty && changes.isNotEmpty && expectedLen > 0) {
        verifyDoc.dispose();
        throw StateError(
          'Snapshot round-trip produced empty text despite '
          '${changes.length} folded ops and $expectedLen nodes in the '
          'snapshot. Aborting before write.',
        );
      }
      verifyDoc.dispose();

      await tx.execute(
        Sql.named('''
          INSERT INTO artifact_snapshots
            (artifact_id, vault_id, snapshot_bytes, version_vector, max_op_seq)
          VALUES (@aid::uuid, @vid::uuid, @bytes, @vv::jsonb, @mseq)
          ON CONFLICT (artifact_id) DO UPDATE SET
            snapshot_bytes = EXCLUDED.snapshot_bytes,
            version_vector = EXCLUDED.version_vector,
            max_op_seq     = EXCLUDED.max_op_seq,
            created_at     = NOW()
        '''),
        parameters: {
          'aid': artifactId,
          'vid': vaultId,
          'bytes': base64Encode(snapBytes),
          'vv': versionVectorJson,
          'mseq': newMaxOpSeq,
        },
      );

      await tx.execute(
        Sql.named('''
          DELETE FROM artifact_ops
          WHERE artifact_id = @aid::uuid
            AND op_seq <= @mseq
        '''),
        parameters: {
          'aid': artifactId,
          'mseq': newMaxOpSeq,
        },
      );
    } finally {
      doc.dispose();
    }

    stdout.writeln(
      'Compacted artifact=$artifactId vault=$vaultId '
      'foldedOps=${changes.length} newMaxOpSeq=$newMaxOpSeq',
    );
    return true;
  });
}

// Codec helpers — mirror lib/bard/_bard_crdt_engine.dart:125-141 so the worker
// reads and writes bytes in the same shape clients do.
Change _decodeChange(Uint8List bytes) =>
    Change.fromJson(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);

Uint8List _encodeSnapshot(Snapshot snap) =>
    Uint8List.fromList(utf8.encode(jsonEncode(snap.toJson())));

Snapshot _decodeSnapshot(Uint8List bytes) {
  final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  final raw = Snapshot.fromJson(json);
  // crdt_lf 2.5.0's Snapshot.fromJson does only a shallow Map.from on `data`,
  // so the handler's `is List<FugueValueNode<String>>` check (in
  // _initialState) fails after a JSON round-trip and the text loads empty.
  // Rebuild the typed content list here.
  final content = raw.data['content'];
  if (content is List) {
    final typed = content
        .map(
          (e) => FugueValueNode<String>.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    return Snapshot(
      id: raw.id,
      versionVector: raw.versionVector,
      data: {...raw.data, 'content': typed},
    );
  }
  return raw;
}
