abstract final class Routes {
  static const String home = '/';
  static const String graph = 'graph';
  static const String resetPassword = '/reset-password';

  static String vaultUrl(String? vaultId) =>
      (vaultId == null || vaultId.isEmpty) ? '/vaults/' : '/vault/$vaultId/';

  static String graphUrl(String? vaultId) =>
      (vaultId == null || vaultId.isEmpty)
      ? vaultUrl(vaultId)
      : '${vaultUrl(vaultId)}$graph';

  static String artifactUrl({required String? vaultId, required String name}) =>
      (vaultId == null || vaultId.isEmpty)
      ? vaultUrl(vaultId)
      : '${vaultUrl(vaultId)}$name';
}
