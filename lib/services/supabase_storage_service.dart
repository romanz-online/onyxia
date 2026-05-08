import 'dart:io';
import 'package:onyxia/export.dart';
import 'package:onyxia/data/models/storage_file.dart';
import 'package:path/path.dart' as path;

/// Service for handling Supabase Storage operations.
/// API surface mirrors the prior Firebase-backed `FileStorageService` so
/// callers (file_storage.dart) need minimal changes.
class FileStorageService {
  static final FileStorageService _instance = FileStorageService._internal();
  factory FileStorageService() => _instance;
  FileStorageService._internal();

  static const Uuid _uuid = Uuid();

  static const int maxImageSize = 10 * 1024 * 1024;
  static const int maxMediaSize = 100 * 1024 * 1024;
  static const int maxDocumentSize = 50 * 1024 * 1024;
  static const int maxAudioSize = 50 * 1024 * 1024;

  static const List<String> allowedImageTypes = [
    'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp',
  ];
  static const List<String> allowedMediaTypes = [
    'video/mp4', 'video/avi', 'video/mov', 'video/wmv', 'video/webm',
    'video/quicktime', 'video/x-msvideo', 'video/x-matroska',
  ];
  static const List<String> allowedAudioTypes = [
    'audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4', 'audio/aac',
    'audio/flac', 'audio/x-flac',
  ];
  static const List<String> allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain', 'text/csv', 'text/markdown', 'text/html',
    'application/rtf',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ];

  SupabaseClient get _client => Supabase.instance.client;

  /// Upload a file. `userId` routes to the `avatars` bucket; otherwise
  /// `projectId` routes to `project-files`. Throws if neither is provided.
  Future<StorageFile> uploadFile({
    dynamic fileData,
    required String fileName,
    required String mimeType,
    required String uploadedBy,
    String? projectId,
    String? canvasId,
    String? userId,
    String? folderId,
    String? folder,
    Function(double progress)? onProgress,
    Map<String, dynamic>? metadata,
  }) async {
    _validateFile(mimeType, fileData);

    final fileId = _uuid.v4();
    final bucket = _bucketFor(userId: userId, projectId: projectId);
    final storagePath = _buildStoragePath(
      fileId: fileId,
      fileName: fileName,
      projectId: projectId,
      canvasId: canvasId,
      userId: userId,
      folderId: folderId,
      folder: folder,
    );

    Uint8List bytes;
    if (fileData is Uint8List) {
      bytes = fileData;
    } else if (fileData is File) {
      bytes = await fileData.readAsBytes();
    } else {
      throw ArgumentError('Unsupported file data type. Use File or Uint8List.');
    }

    // Supabase Storage doesn't expose granular progress callbacks; emit 0 → 1.
    onProgress?.call(0);
    await _client.storage.from(bucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true,
          ),
        );
    onProgress?.call(1);

    final downloadUrl = _client.storage.from(bucket).getPublicUrl(storagePath);

    return StorageFile(
      id: fileId,
      name: fileName,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      sizeBytes: bytes.length,
      mimeType: mimeType,
      uploadedAt: DateTime.now(),
      uploadedBy: uploadedBy,
      projectId: projectId,
      metadata: metadata,
    );
  }

  /// Upload multiple files concurrently.
  Future<List<StorageFile>> uploadMultipleFiles({
    required List<dynamic> fileDataList,
    required List<String> fileNames,
    required List<String> mimeTypes,
    required String uploadedBy,
    String? projectId,
    String? canvasId,
    String? folder,
    Function(int completed, int total)? onProgress,
    Map<String, dynamic>? metadata,
  }) async {
    if (fileDataList.length != fileNames.length || fileNames.length != mimeTypes.length) {
      throw ArgumentError('All lists must have the same length');
    }

    final results = <StorageFile>[];
    for (int i = 0; i < fileDataList.length; i++) {
      final result = await uploadFile(
        fileData: fileDataList[i],
        fileName: fileNames[i],
        mimeType: mimeTypes[i],
        uploadedBy: uploadedBy,
        projectId: projectId,
        canvasId: canvasId,
        folder: folder,
        metadata: metadata,
      );
      results.add(result);
      onProgress?.call(i + 1, fileDataList.length);
    }
    return results;
  }

  Future<Uint8List?> downloadFile(
    String storagePath, {
    int maxSize = 10 * 1024 * 1024,
  }) async {
    final bucket = _bucketForPath(storagePath);
    return _client.storage.from(bucket).download(_stripBucketPrefix(storagePath));
  }

  Future<String> getDownloadUrl(String storagePath) async {
    final bucket = _bucketForPath(storagePath);
    return _client.storage.from(bucket).getPublicUrl(_stripBucketPrefix(storagePath));
  }

  Future<void> deleteFile(String storagePath) async {
    final bucket = _bucketForPath(storagePath);
    await _client.storage.from(bucket).remove([_stripBucketPrefix(storagePath)]);
  }

  Future<List<String>> deleteMultipleFiles(List<String> storagePaths) async {
    final failedDeletes = <String>[];
    for (final p in storagePaths) {
      try {
        await deleteFile(p);
      } catch (_) {
        failedDeletes.add(p);
      }
    }
    return failedDeletes;
  }

  Future<bool> fileExists(String storagePath) async {
    try {
      await getDownloadUrl(storagePath);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ------------- Private helpers -------------

  String _bucketFor({String? userId, String? projectId}) {
    if (userId != null && projectId == null) return 'avatars';
    if (projectId != null) return 'project-files';
    return 'project-files';
  }

  /// Best-effort bucket inference for paths that already include the bucket
  /// prefix (`users/...` → avatars, `projects/...` → project-files).
  String _bucketForPath(String storagePath) {
    if (storagePath.startsWith('users/')) return 'avatars';
    return 'project-files';
  }

  /// The first segment of the path is sometimes a bucket-equivalent ('users',
  /// 'projects', 'general'); Supabase paths are bucket-relative, so we keep
  /// the whole path inside the bucket — no stripping needed.
  String _stripBucketPrefix(String storagePath) => storagePath;

  void _validateFile(String mimeType, dynamic fileData) {
    final isValidType = allowedImageTypes.contains(mimeType) ||
        allowedMediaTypes.contains(mimeType) ||
        allowedAudioTypes.contains(mimeType) ||
        allowedDocumentTypes.contains(mimeType);
    if (!isValidType) {
      throw ArgumentError('Unsupported file type: $mimeType');
    }

    int fileSize = 0;
    if (fileData is Uint8List) {
      fileSize = fileData.length;
    } else if (fileData is File) {
      fileSize = fileData.lengthSync();
    }

    if (allowedImageTypes.contains(mimeType) && fileSize > maxImageSize) {
      throw ArgumentError('Image file too large. Max: ${maxImageSize ~/ (1024 * 1024)}MB');
    } else if (allowedMediaTypes.contains(mimeType) && fileSize > maxMediaSize) {
      throw ArgumentError('Media file too large. Max: ${maxMediaSize ~/ (1024 * 1024)}MB');
    } else if (allowedAudioTypes.contains(mimeType) && fileSize > maxAudioSize) {
      throw ArgumentError('Audio file too large. Max: ${maxAudioSize ~/ (1024 * 1024)}MB');
    } else if (allowedDocumentTypes.contains(mimeType) && fileSize > maxDocumentSize) {
      throw ArgumentError('Document file too large. Max: ${maxDocumentSize ~/ (1024 * 1024)}MB');
    }
  }

  String _buildStoragePath({
    required String fileId,
    required String fileName,
    String? projectId,
    String? canvasId,
    String? userId,
    String? folderId,
    String? folder,
  }) {
    final parts = <String>[];

    if (userId != null) {
      parts..add('users')..add(userId);
    } else if (projectId != null) {
      parts..add('projects')..add(projectId);
    } else {
      parts.add('general');
    }

    if (canvasId != null) {
      parts..add('userExperience')..add(canvasId);
    } else if (folderId != null) {
      parts..addAll(['userExperience', 'markup', folderId]);
    } else if (folder == 'file-uploads') {
      parts..addAll(['userExperience', 'markup', 'file-upload', fileId]);
    }

    if (folder != null && folder != 'file-uploads') {
      parts.add(folder);
    } else if (folder == null) {
      parts.add('files');
    } else if (folder == 'file-uploads') {
      parts.add('images');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(fileName);
    final baseName = path.basenameWithoutExtension(fileName);
    parts.add('${timestamp}_${fileId}_$baseName$extension');

    return parts.join('/');
  }
}
