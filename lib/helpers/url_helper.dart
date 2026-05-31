import 'package:onyxia/export.dart';
import 'package:web/web.dart' as web;

class UrlHelper {
  UrlHelper._();

  static String toShareableUrl(String relativePath) {
    if (relativePath.startsWith('http')) return relativePath;
    final path = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '${Uri.base.origin}$path';
  }

  static void openInNewTab(String relativePath) =>
      web.window.open(toShareableUrl(relativePath), '_blank');

  static void copyLinkToClipboard(String relativePath) =>
      Clipboard.setData(ClipboardData(text: toShareableUrl(relativePath)));
}
