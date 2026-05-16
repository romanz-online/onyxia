import 'package:onyxia/export.dart';

class VaultMembersRepository extends BaseSupabaseRepository<VaultMember> {
  VaultMembersRepository({required super.vaultId});

  @override
  String get tableName => 'vault_members';

  @override
  String get scopeField => 'vault_id';

  @override
  List<String> get primaryKeyFields => const ['vault_id', 'user_id'];

  @override
  Map<String, dynamic> keyFilter(VaultMember item) => {
        'vault_id': item.vaultId,
        'user_id': item.userId,
      };

  @override
  VaultMember fromMap(Map<String, dynamic> map) => VaultMember.fromMap(map);

  @override
  Map<String, dynamic> toMap(VaultMember item) => item.toMap();

  /// Unused for composite-key tables — the base contract still requires it.
  @override
  String getIdFromItem(VaultMember item) => item.userId;
}
