import 'package:onyxia/export.dart';

final vaultsProvider = StreamNotifierProvider<VaultsNotifier, List<Vault>>(
  VaultsNotifier.new,
);

class VaultsNotifier extends StreamNotifier<List<Vault>> {
  final VaultsRepository _repository = VaultsRepository();

  @override
  Stream<List<Vault>> build() => _repository.getStream();

  void renameVault(String id, String newName) {
    final p = state.value?.firstWhereOrNull((e) => e.id == id);
    if (p == null) return;
    _repository.update([p.copyWith(name: newName)]);
  }
}
