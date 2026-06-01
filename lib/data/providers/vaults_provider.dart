import 'package:onyxia/export.dart';

final vaultsProvider = StreamNotifierProvider<VaultsNotifier, List<Vault>>(
  VaultsNotifier.new,
);

class VaultsNotifier extends StreamNotifier<List<Vault>> {
  late VaultsRepository _repository;

  @override
  Stream<List<Vault>> build() {
    final userId = ref.watch(currentUserProvider.select((u) => u.value?.id));
    _repository = VaultsRepository();
    if (userId == null || userId.isEmpty) return Stream.value(const <Vault>[]);
    return _repository.getStream();
  }

  void renameVault(String id, String newName) {
    final p = state.value?.firstWhereOrNull((e) => e.id == id);
    if (p == null) return;
    _repository.update([p.copyWith(name: newName)]);
  }
}
