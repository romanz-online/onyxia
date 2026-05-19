import 'dart:convert';

import 'package:onyxia/export.dart';

class ArtifactOp {
  final String id;
  final String artifactId;
  final String vaultId;
  final String userId;
  final Uint8List opBytes;
  final int? opSeq;
  final DateTime? createdAt;

  ArtifactOp({
    required this.id,
    required this.artifactId,
    required this.vaultId,
    required this.userId,
    required this.opBytes,
    this.opSeq,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'artifact_id': artifactId,
      'op_bytes': base64Encode(opBytes),
    };
  }

  ArtifactOp.fromMap(Map<String, dynamic> map)
      : id = map['id'] as String,
        artifactId = map['artifact_id'] as String,
        vaultId = map['vault_id'] as String,
        userId = map['user_id'] as String,
        opBytes = base64Decode(map['op_bytes'] as String),
        opSeq = map['op_seq'] as int?,
        createdAt = TimestampService.fromMap(map['created_at']);
}
