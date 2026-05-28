import 'package:onyxia/export.dart';

class VaultInvitation {
  final String token;
  final String vaultId;
  final String email;
  final DateTime? expiresAt;

  VaultInvitation({
    required this.token,
    required this.vaultId,
    required this.email,
    this.expiresAt,
  });

  VaultInvitation copyWith({
    String? token,
    String? vaultId,
    String? email,
    DateTime? expiresAt,
  }) => VaultInvitation(
    token: token ?? this.token,
    vaultId: vaultId ?? this.vaultId,
    email: email ?? this.email,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  Map<String, dynamic> toMap() => {
    'token': token,
    'vault_id': vaultId,
    'email': email,
  };

  VaultInvitation.fromMap(Map<String, dynamic> map)
    : token = map['token'] ?? '',
      vaultId = map['vault_id'] ?? '',
      email = map['email'] ?? '',
      expiresAt = TimestampService.fromMap(map['expires_at']);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultInvitation &&
          other.token == token &&
          other.vaultId == vaultId &&
          other.email == email;

  @override
  int get hashCode => Object.hash(token, vaultId, email);

  @override
  String toString() =>
      'VaultInvitation(token: $token, vaultId: $vaultId, email: $email)';
}
