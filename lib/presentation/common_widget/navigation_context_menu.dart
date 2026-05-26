import 'package:onyxia/export.dart';
import 'package:web/web.dart' as web;

/// Context menu for navigation elements that provides web-like functionality
/// including "Open in New Tab" and "Copy Link" options
class NavigationContextMenu {
  /// Opens the given URL in a new browser tab
  static void openInNewTab(String url) {
    if (kIsWeb) {
      web.window.open(url, '_blank');
    }
  }

  /// Copies the URL to the clipboard
  static void copyLinkToClipboard(String url) {
    final fullUrl = _buildFullUrl(url);
    Clipboard.setData(ClipboardData(text: fullUrl)).then((_) {
      OnyxiaToast.show(text: 'Link copied to clipboard', type: ToastType.info);
    });
  }

  /// Builds a full URL from the relative path
  static String _buildFullUrl(String relativePath) {
    // Handle absolute URLs
    if (relativePath.startsWith('http')) {
      return relativePath;
    }

    final currentUrl = web.window.location.href;
    final uri = Uri.parse(currentUrl);
    final baseUrl =
        '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';

    // For hash routing URLs (like /#/vault/123), just append to base URL
    if (relativePath.startsWith('/#/') || relativePath.startsWith('#/')) {
      return '$baseUrl$relativePath';
    }
    if (relativePath.startsWith('/')) {
      return '$baseUrl$relativePath';
    }
    return '$baseUrl/$relativePath';
  }
}
