import 'package:onyxia/export.dart';

final vaultMembersProvider =
    StreamProvider.autoDispose<List<VaultMember>>((ref) {
  final vaultId = ref.watch(selectedVaultProvider.select((p) => p?.id));
  if (vaultId == null) return Stream.value([]);
  return VaultMembersRepository(vaultId: vaultId).getStream();
});
