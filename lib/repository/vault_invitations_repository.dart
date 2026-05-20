import 'package:onyxia/export.dart';

class VaultInvitationsRepository extends BaseSupabaseRepository<VaultInvitation> {
  VaultInvitationsRepository({required super.vaultId});

  @override
  String get tableName => 'vault_invitations';

  @override
  String get scopeField => 'vault_id';

  @override
  List<String> get primaryKeyFields => const ['token'];

  @override
  Map<String, dynamic> keyFilter(VaultInvitation item) =>
      {'token': item.token};

  @override
  VaultInvitation fromMap(Map<String, dynamic> map) =>
      VaultInvitation.fromMap(map);

  @override
  Map<String, dynamic> toMap(VaultInvitation item) => item.toMap();

  @override
  String getIdFromItem(VaultInvitation item) => item.token;
}
