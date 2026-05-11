import 'package:onyxia/export.dart';

class StorageFile {
  /// Unique identifier for the file
  final String id;

  /// Original filename provided by user
  final String name;

  /// Full path in Firebase Storage (e.g., 'projects/project1/images/image.jpg')
  final String storagePath;

  /// Public download URL for the file
  final String downloadUrl;

  /// File size in bytes
  final int sizeBytes;

  /// MIME type of the file (e.g., 'image/jpeg', 'application/pdf')
  final String mimeType;

  /// Optional project ID this file belongs to
  final String? projectId;

  /// Optional metadata for additional information
  final Map<String, dynamic>? metadata;

  //
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  StorageFile({
    required this.id,
    required this.name,
    required this.storagePath,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.mimeType,
    this.projectId,
    this.metadata,
    //
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  StorageFile.fromMap(Map<String, dynamic> map)
      : id = map['id'] ?? '',
        name = map['name'] ?? '',
        storagePath = map['path'] ?? '',
        downloadUrl = map['download_url'] ?? '',
        sizeBytes = (map['size'] as num?)?.toInt() ?? 0,
        mimeType = map['mime'] ?? '',
        projectId = map['project_id'] ?? '',
        metadata = map['metadata'] as Map<String, dynamic>?,
        //
        createdAt = TimestampService.fromMap(map['created_at']),
        createdBy = map['created_by'] ?? '',
        updatedAt = TimestampService.fromMap(map['updated_at']),
        updatedBy = map['updated_by'] ?? '';

  /// Top-level Postgres columns. `download_url` is computed from `path` at read
  /// time via Supabase Storage and is never persisted.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': storagePath,
      'size': sizeBytes,
      'mime': mimeType,
      'project_id': projectId,
      'metadata': metadata,
    };
  }

  String get fileExtension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  bool get isImage => mimeType.startsWith('image/');

  bool get isMedia => mimeType.startsWith('video/');

  bool get isAudio => mimeType.startsWith('audio/');

  bool get isDocument =>
      mimeType.startsWith('application/') ||
      mimeType.startsWith('text/') ||
      ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(fileExtension);

  /// Get human-readable file size
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024)
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024)
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Create a copy with updated fields
  StorageFile copyWith({
    String? id,
    String? name,
    String? storagePath,
    String? downloadUrl,
    int? sizeBytes,
    String? mimeType,
    String? projectId,
    Map<String, dynamic>? metadata,
  }) {
    return StorageFile(
      id: id ?? this.id,
      name: name ?? this.name,
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      projectId: projectId ?? this.projectId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'StorageFile(id: $id, '
        'name: $name, '
        'size: $formattedSize, '
        'type: $mimeType, '
        //
        'createdAt: $createdAt, '
        'createdBy: $createdBy, '
        'updatedAt: $updatedAt, '
        'updatedBy: $updatedBy, '
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StorageFile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
