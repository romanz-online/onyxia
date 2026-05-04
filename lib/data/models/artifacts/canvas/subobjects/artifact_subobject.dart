class ArtifactProperties {
  final String artifactId;

  ArtifactProperties({
    required this.artifactId,
  });

  factory ArtifactProperties.initial() {
    return ArtifactProperties(artifactId: '');
  }

  @override
  String toString() {
    return 'ArtifactProperties('
        'artifactId: $artifactId, '
        ')';
  }

  Map<String, dynamic> toMap() {
    return {'artifactId': artifactId};
  }

  factory ArtifactProperties.fromMap(Map<String, dynamic> map) {
    return ArtifactProperties(artifactId: map['artifactId'] ?? '');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ArtifactProperties && other.artifactId == artifactId;
  }

  @override
  int get hashCode {
    return artifactId.hashCode;
  }
}
