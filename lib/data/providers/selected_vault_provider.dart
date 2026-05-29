import 'package:onyxia/export.dart';

final selectedVaultProvider = Provider<Vault?>((ref) {
  final id = ref.watch(_selectedVaultIdFromUrlProvider);
  if (id == null || id.isEmpty) return null;
  final vaults = ref.watch(vaultsProvider).value ?? const [];
  return vaults.firstWhereOrNull((p) => p.id == id);
});

final _selectedVaultIdFromUrlProvider =
    NotifierProvider<_SelectedVaultIdFromUrlNotifier, String?>(
      _SelectedVaultIdFromUrlNotifier.new,
    );

class _SelectedVaultIdFromUrlNotifier extends Notifier<String?> {
  @override
  String? build() {
    final router = ref.watch(routerProvider);
    void listener() {
      state = router.routerDelegate.currentConfiguration.pathParameters['id'];
    }

    router.routeInformationProvider.addListener(listener);
    ref.onDispose(() {
      router.routeInformationProvider.removeListener(listener);
    });
    return router.routerDelegate.currentConfiguration.pathParameters['id'];
  }
}
