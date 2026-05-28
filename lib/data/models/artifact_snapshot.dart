import 'dart:convert';

import 'package:onyxia/export.dart';

class ArtifactSnapshot {
  final String artifactId;
  final String vaultId;
  final Uint8List snapshotBytes;
  final Map<String, dynamic> versionVector;
  final int? maxOpSeq;
  final DateTime? createdAt;

  ArtifactSnapshot({
    required this.artifactId,
    required this.vaultId,
    required this.snapshotBytes,
    required this.versionVector,
    this.maxOpSeq,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'artifact_id': artifactId,
      'snapshot_bytes': base64Encode(snapshotBytes),
      'version_vector': versionVector,
      'max_op_seq': maxOpSeq,
    };
  }

  ArtifactSnapshot.fromMap(Map<String, dynamic> map)
    : artifactId = map['artifact_id'] as String,
      vaultId = map['vault_id'] as String,
      snapshotBytes = base64Decode(map['snapshot_bytes'] as String),
      versionVector = Map<String, dynamic>.from(map['version_vector'] as Map),
      maxOpSeq = map['max_op_seq'] as int?,
      createdAt = TimestampService.fromMap(map['created_at']);
}
