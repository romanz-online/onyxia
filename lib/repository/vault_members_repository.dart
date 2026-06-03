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

  /// Adds a member to this vault by email via the `add_vault_member_by_email`
  /// RPC. If no account exists for [email] yet, the RPC creates a "ghost" user
  /// that becomes the real account once that person signs up.
  ///
  /// Returns the resolved [User] (registered or ghost). Throws if the caller
  /// isn't an owner/admin of the vault.
  Future<User> addByEmail({
    required String email,
    UserRole role = UserRole.member,
  }) async {
    final row =
        await Supabase.instance.client.rpc(
              'add_vault_member_by_email',
              params: {
                'p_vault_id': vaultId,
                'p_email': email,
                'p_role': role.value,
              },
            )
            as Map<String, dynamic>;
    return User.fromMap(row);
  }
}
