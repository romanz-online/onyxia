import 'package:onyxia/export.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

/// Context menu for navigation elements that provides web-like functionality
/// including "Open in New Tab" and "Copy Link" options
class NavigationContextMenu {
  static List<ContextMenuEntry> buildNavigationMenu({
    required String url,
    required String title,
    VoidCallback? onOpenInNewTab,
    VoidCallback? onCopyLink,
  }) {
    return [
      ContextMenuEntry(
        label: 'Open in New Tab',
        icon: Icons.open_in_new,
        onTap: onOpenInNewTab ?? () => openInNewTab(url),
      ),
      ContextMenuEntry(
        label: 'Copy Link',
        icon: Icons.link,
        onTap: onCopyLink ?? () => copyLinkToClipboard(url),
      ),
    ];
  }

  /// Opens the given URL in a new browser tab
  static void openInNewTab(String url) {
    if (kIsWeb) {
      web.window.open(url, '_blank');
    } else {
      _launchInBrowser(Uri.parse(_buildFullUrl(url)));
    }
  }

  static Future<void> _launchInBrowser(Uri url) async {
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('Failed to launch URL: $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  /// Copies the URL to the clipboard
  static void copyLinkToClipboard(String url) {
    final fullUrl = _buildFullUrl(url);
    Clipboard.setData(ClipboardData(text: fullUrl)).then((_) {
      // You could show a toast notification here if needed
      // NarwhalToast.show(text: 'Link copied to clipboard', type: ToastType.info);
    });
  }

  /// Builds a full URL from the relative path
  static String _buildFullUrl(String relativePath) {
    // Handle absolute URLs
    if (relativePath.startsWith('http')) {
      return relativePath;
    }
    String baseUrl;
    if (kIsWeb) {
      final currentUrl = web.window.location.href;
      final uri = Uri.parse(currentUrl);
      baseUrl = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';

      // For hash routing URLs (like /#/project/123), just append to base URL
      if (relativePath.startsWith('/#/') || relativePath.startsWith('#/')) {
        return '$baseUrl$relativePath';
      }
      if (relativePath.startsWith('/')) {
        return '$baseUrl$relativePath';
      }
      return '$baseUrl/$relativePath';
    } else {
      // For non-web platforms, always use hash routing
      baseUrl = 'https://narwhal-flutter-staging.web.app';

      // Remove leading slash if present and add hash routing
      String path = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
      return '$baseUrl/#/$path';
    }
  }
}

/// Context menu entry model for navigation menus
class ContextMenuEntry {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const ContextMenuEntry({
    required this.label,
    this.icon,
    required this.onTap,
  });
}
