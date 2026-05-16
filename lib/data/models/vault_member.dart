import 'package:onyxia/export.dart';

enum UserRole with NarwhalEnum {
  member,
  admin,
  owner;

  String get label => switch (this) {
        UserRole.member => 'Member',
        UserRole.admin => 'Admin',
        UserRole.owner => 'Owner',
      };
}

class VaultMember {
  final String vaultId;
  final String userId;
  final UserRole role;
  //
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  VaultMember({
    required this.vaultId,
    required this.userId,
    required this.role,
    //
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  VaultMember copyWith({
    String? vaultId,
    String? userId,
    UserRole? role,
  }) =>
      VaultMember(
        vaultId: vaultId ?? this.vaultId,
        userId: userId ?? this.userId,
        role: role ?? this.role,
      );

  Map<String, dynamic> toMap() => {
        'vault_id': vaultId,
        'user_id': userId,
        'role': role.value,
      };

  VaultMember.fromMap(Map<String, dynamic> map)
      : vaultId = map['vault_id'] ?? '',
        userId = map['user_id'] ?? '',
        role = UserRole.values.fromString(map['role'] ?? ''),
        //
        createdAt = TimestampService.fromMap(map['created_at']),
        createdBy = map['created_by'] ?? '',
        updatedAt = TimestampService.fromMap(map['updated_at']),
        updatedBy = map['updated_by'] ?? '';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VaultMember &&
        other.vaultId == vaultId &&
        other.userId == userId &&
        //
        other.createdAt == createdAt &&
        other.createdBy == createdBy &&
        other.updatedAt == updatedAt &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return vaultId.hashCode ^
        userId.hashCode ^
        role.hashCode ^
        //
        createdAt.hashCode ^
        createdBy.hashCode ^
        updatedAt.hashCode ^
        updatedBy.hashCode;
  }

  @override
  String toString() => 'VaultMember('
      'vaultId: $vaultId, '
      'userId: $userId, '
      'role: ${role.value}, '
      ')';
}
