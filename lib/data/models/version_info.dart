class PlatformVersionInfo {
  final String latestVersion;
  final String? minSupportedVersion;
  final String? downloadUrl;

  const PlatformVersionInfo({
    required this.latestVersion,
    this.minSupportedVersion,
    this.downloadUrl,
  });

  factory PlatformVersionInfo.fromJson(Map<String, dynamic> json) {
    return PlatformVersionInfo(
      latestVersion: json['latestVersion'] as String,
      minSupportedVersion: json['minSupportedVersion'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latestVersion': latestVersion,
      if (minSupportedVersion != null) 'minSupportedVersion': minSupportedVersion,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
    };
  }
}

class VersionInfo {
  final Map<String, PlatformVersionInfo> platforms;

  const VersionInfo({
    required this.platforms,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    final platformsData = json['platforms'] as Map<String, dynamic>;
    final platforms = <String, PlatformVersionInfo>{};

    platformsData.forEach((key, value) {
      platforms[key] = PlatformVersionInfo.fromJson(value as Map<String, dynamic>);
    });

    return VersionInfo(platforms: platforms);
  }

  Map<String, dynamic> toJson() {
    return {
      'platforms': platforms.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  /// Get version info for specific platform
  PlatformVersionInfo? getPlatformInfo(String platform) {
    return platforms[platform];
  }

  @override
  String toString() => 'VersionInfo(platforms: ${platforms.keys.join(", ")})';
}
