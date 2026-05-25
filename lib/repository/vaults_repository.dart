import 'package:onyxia/export.dart';

class VaultsRepository extends BaseSupabaseRepository<Vault> {
  @override
  String get tableName => 'vaults';

  @override
  bool get requireVaultId => false;

  @override
  Vault fromMap(Map<String, dynamic> map) => Vault.fromMap(map);

  @override
  Map<String, dynamic> toMap(Vault item) => item.toMap();

  @override
  String getIdFromItem(Vault item) => item.id;
}
