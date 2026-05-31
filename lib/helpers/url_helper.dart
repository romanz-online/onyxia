import 'package:onyxia/export.dart';
import 'package:web/web.dart' as web;

/// Single source of truth for URL/route paths across the app.
///
/// Three layers, each with a distinct contract:
/// 1. Path builders → relative GoRouter paths (e.g. `/vault/X/graph`).
/// 2. Shareable-URL adapter → absolute URL for browser/clipboard sharing.
/// 3. Browser actions → take a relative path; handle the adapter internally.
class UrlHelper {
  UrlHelper._();

  // ===== Layer 1: relative path builders =====

  static String artifactPath({
    required String? vaultId,
    required String name,
  }) => (vaultId == null || vaultId.isEmpty) ? '' : '/vault/$vaultId/$name';

  static String vaultGraphPath(String vaultId) =>
      vaultId.isEmpty ? '/vaults' : '/vault/$vaultId/${Routes.graph}';

  // ===== Layer 2: shareable URL adapter =====

  /// Converts a relative GoRouter path into an absolute, hash-routed URL
  /// suitable for sharing (clipboard, new tab). Off-web, returns the input
  /// unchanged.
  static String toShareableUrl(String relativePath) {
    if (!kIsWeb) return relativePath;
    if (relativePath.startsWith('http')) return relativePath;

    final uri = Uri.parse(web.window.location.href);
    final port = (uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
    final baseUrl = '${uri.scheme}://${uri.host}$port';

    if (relativePath.startsWith('/#/') || relativePath.startsWith('#/')) {
      return '$baseUrl$relativePath';
    }
    final path = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$baseUrl/#$path';
  }

  // ===== Layer 3: browser actions (web-only; no-op elsewhere) =====

  static void openInNewTab(String relativePath) {
    // TODO: this is entirely a web app. need to put that into claude.md and remove unneeded web-checks and logic from everywhere (constellation excluded)
    if (!kIsWeb) return;
    web.window.open(toShareableUrl(relativePath), '_blank');
  }

  static void copyLinkToClipboard(String relativePath) {
    if (!kIsWeb) return;
    Clipboard.setData(ClipboardData(text: toShareableUrl(relativePath)));
  }
}
