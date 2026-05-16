import 'package:web/web.dart' as web;

/// Utility class for building navigation URLs for Flutter web Link widgets
/// Ensures consistent URL generation across the application with proper hash routing
class NavigationUrlBuilder {
  /// Detects if the app is using hash routing and returns appropriate base URL
  static String _getBaseUrl() {
    try {
      // Check current URL to determine routing strategy
      final currentUrl = web.window.location.href;
      final currentHash = web.window.location.hash;

      // If current URL contains hash routing (/#/), use hash-based URLs
      if (currentHash.startsWith('#/') || currentUrl.contains('/#/')) {
        return '/#';
      }

      // Otherwise, assume path-based routing
      return '';
    } catch (e) {
      // Fallback to hash routing (Flutter web default)
      return '/#';
    }
  }

  /// Builds URL for vault dashboard (constellation view)
  static String buildGraphUrl(String vaultId) {
    if (vaultId.isEmpty) return '${_getBaseUrl()}/vaults';
    return '${_getBaseUrl()}/vault/$vaultId/graph';
  }
}
