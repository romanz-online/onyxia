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

  /// When the file was uploaded
  final DateTime uploadedAt;

  /// User ID who uploaded the file
  final String uploadedBy;

  /// Optional project ID this file belongs to
  final String? projectId;

  /// Optional metadata for additional information
  final Map<String, dynamic>? metadata;

  StorageFile({
    required this.id,
    required this.name,
    required this.storagePath,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.mimeType,
    required this.uploadedAt,
    required this.uploadedBy,
    this.projectId,
    this.metadata,
  });

  factory StorageFile.fromMap(Map<String, dynamic> map) {
    DateTime parseTs(dynamic v) {
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.now();
    }

    return StorageFile(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '',
      storagePath: (map['path'] as String?) ?? '',
      downloadUrl: (map['download_url'] as String?) ?? '',
      sizeBytes: (map['size'] as num?)?.toInt() ?? 0,
      mimeType: (map['mime'] as String?) ?? '',
      uploadedAt: parseTs(map['created_at']),
      uploadedBy: (map['user_id'] as String?) ?? '',
      projectId: map['project_id'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Top-level Postgres columns. `download_url` is computed from `path` at read
  /// time via Supabase Storage and is never persisted.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': storagePath,
      'size': sizeBytes,
      'mime': mimeType,
      'user_id': uploadedBy,
      'project_id': projectId,
      'metadata': metadata,
    };
  }

  /// Get file extension from name
  String get fileExtension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is an image
  bool get isImage {
    return mimeType.startsWith('image/');
  }

  /// Check if file is a video
  bool get isMedia {
    return mimeType.startsWith('video/');
  }

  /// Check if file is audio
  bool get isAudio {
    return mimeType.startsWith('audio/');
  }

  /// Check if file is a document
  bool get isDocument {
    return mimeType.startsWith('application/') ||
        mimeType.startsWith('text/') ||
        ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(fileExtension);
  }

  /// Get human-readable file size
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
    DateTime? uploadedAt,
    String? uploadedBy,
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
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      projectId: projectId ?? this.projectId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'StorageFile(id: $id, name: $name, size: $formattedSize, type: $mimeType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StorageFile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
