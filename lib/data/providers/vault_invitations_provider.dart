import 'package:onyxia/export.dart';

final vaultInvitationsProvider =
    StreamProvider.autoDispose<List<VaultInvitation>>((ref) {
      final vaultId = ref.watch(selectedVaultProvider.select((p) => p?.id));
      if (vaultId == null) return Stream.value(const []);
      return VaultInvitationsRepository(vaultId: vaultId).getStream();
    });
