import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/version_info.dart';

class UpdateCheckResult {
  final bool hasUpdate;
  final String? latestVersion;
  final String? downloadUrl;
  final bool isMinVersionSupported;

  const UpdateCheckResult({
    required this.hasUpdate,
    this.latestVersion,
    this.downloadUrl,
    this.isMinVersionSupported = true,
  });
}

class VersionCheckService {
  // URL to JSON file in Firebase Hosting
  static const String _versionCheckUrl =
      'https://narwhal-flutter-updates.web.app/version.json';

  static const String _lastCheckKey = 'last_version_check';
  static const String _dismissedVersionKey = 'dismissed_version';

  /// Check if a new version is available
  static Future<UpdateCheckResult?> checkForUpdate(String currentVersion) async {
    try {
      final platform = getCurrentPlatform();

      // Don't check on web
      if (platform == 'web') return null;

      // Fetch version info from server
      final response = await http.get(Uri.parse(_versionCheckUrl));

      if (response.statusCode != 200) {
        debugPrint('Failed to fetch version info: ${response.statusCode}');
        return null;
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final versionInfo = VersionInfo.fromJson(jsonData);

      // Get platform specific info
      final platformInfo = versionInfo.getPlatformInfo(platform);
      if (platformInfo == null) {
        debugPrint('No version info for platform: $platform');
        return null;
      }

      // Check if current version is below minimum supported
      final isMinSupported = platformInfo.minSupportedVersion == null ||
          !_isNewerVersion(currentVersion, platformInfo.minSupportedVersion!);

      // Compare versions
      final hasUpdate = _isNewerVersion(currentVersion, platformInfo.latestVersion);

      if (hasUpdate) {
        // Check if user dismissed this version
        final prefs = await SharedPreferences.getInstance();
        final dismissedVersion = prefs.getString(_dismissedVersionKey);

        if (dismissedVersion == platformInfo.latestVersion && isMinSupported) {
          // User dismissed this version and it's not critical
          return null;
        }

        return UpdateCheckResult(
          hasUpdate: true,
          latestVersion: platformInfo.latestVersion,
          downloadUrl: platformInfo.downloadUrl,
          isMinVersionSupported: isMinSupported,
        );
      }

      return const UpdateCheckResult(hasUpdate: false);
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  /// Get current platform name
  static String getCurrentPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Mark that user dismissed this version
  static Future<void> dismissVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, version);
  }

  /// Update last check timestamp
  static Future<void> updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if should check for updates (once per day)
  static Future<bool> shouldCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt(_lastCheckKey);

    if (lastCheck == null) return true;

    final lastCheckDate = DateTime.fromMillisecondsSinceEpoch(lastCheck);
    final now = DateTime.now();
    final difference = now.difference(lastCheckDate);

    return difference.inHours >= 24;
  }

  /// Compare version strings (e.g., "1.0.0" vs "1.0.1")
  /// Returns true if newVersion is newer than currentVersion
  static bool _isNewerVersion(String currentVersion, String newVersion) {
    try {
      // Remove build number if present (e.g., "1.0.0+1" -> "1.0.0")
      currentVersion = currentVersion.split('+').first;
      newVersion = newVersion.split('+').first;

      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final newParts = newVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < currentParts.length && i < newParts.length; i++) {
        if (newParts[i] > currentParts[i]) return true;
        if (newParts[i] < currentParts[i]) return false;
      }

      return newParts.length > currentParts.length;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }
}
