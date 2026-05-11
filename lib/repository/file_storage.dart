import 'package:onyxia/export.dart';
import 'package:onyxia/data/models/storage_file.dart';
import 'package:onyxia/services/supabase_storage_service.dart';

/// High-level repository for storage operations.
/// Combines Supabase Storage uploads (`FileStorageService`) with
/// `storage_files` table metadata (`StorageFilesRepository`).
class FileStorage {
  static final FileStorage _instance = FileStorage._internal();
  factory FileStorage() => _instance;
  FileStorage._internal();

  final FileStorageService _storageService = FileStorageService();
  final StorageFilesRepository _metaRepo = StorageFilesRepository();

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
    final storageFile = await _storageService.uploadFile(
      fileData: fileData,
      fileName: fileName,
      mimeType: mimeType,
      uploadedBy: uploadedBy,
      projectId: projectId,
      canvasId: canvasId,
      userId: userId,
      folderId: folderId,
      folder: folder,
      onProgress: onProgress,
      metadata: metadata,
    );
    await _saveFileMetadata(storageFile);
    return storageFile;
  }

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
    final files = await _storageService.uploadMultipleFiles(
      fileDataList: fileDataList,
      fileNames: fileNames,
      mimeTypes: mimeTypes,
      uploadedBy: uploadedBy,
      projectId: projectId,
      canvasId: canvasId,
      folder: folder,
      onProgress: onProgress,
      metadata: metadata,
    );
    for (final f in files) {
      await _saveFileMetadata(f);
    }
    return files;
  }

  Future<StorageFile?> getFileMetadata(String fileId) => _metaRepo.get(fileId);

  Future<List<StorageFile>> getFilesByProject(String projectId) =>
      _metaRepo.query(
          field: 'project_id',
          isEqualTo: projectId,
          orderBy: 'created_at',
          descending: true);

  Future<List<StorageFile>> getFilesByCanvas(
          String projectId, String canvasId) =>
      _metaRepo.query(
          field: 'canvas_id',
          isEqualTo: canvasId,
          orderBy: 'created_at',
          descending: true);

  Future<List<StorageFile>> getFilesByUser(String userId) => _metaRepo.query(
      field: 'user_id',
      isEqualTo: userId,
      orderBy: 'created_at',
      descending: true);

  Future<List<StorageFile>> getFilesByType({
    String? projectId,
    String? canvasId,
    required StorageFileType fileType,
  }) async {
    final List<String> mimeTypes;
    switch (fileType) {
      case StorageFileType.image:
        mimeTypes = FileStorageService.allowedImageTypes;
        break;
      case StorageFileType.media:
        mimeTypes = FileStorageService.allowedMediaTypes;
        break;
      case StorageFileType.document:
        mimeTypes = FileStorageService.allowedDocumentTypes;
        break;
    }

    // Multi-condition queries: scope server-side by project_id (most selective)
    // and post-filter mime/canvas client-side.
    final all = projectId != null
        ? await _metaRepo.query(
            field: 'project_id',
            isEqualTo: projectId,
            orderBy: 'created_at',
            descending: true)
        : await _metaRepo.getAll();
    return all.where((f) {
      if (canvasId != null && f.metadata?['canvas_id'] != canvasId)
        return false;
      return mimeTypes.contains(f.mimeType);
    }).toList();
  }

  /// Realtime stream over the `storage_files` table, scoped server-side by
  /// project_id when provided.
  Stream<List<StorageFile>> getFilesStream({
    String? projectId,
    String? canvasId,
    String? uploadedBy,
  }) {
    if (projectId != null) {
      return _metaRepo
          .queryStream(
              field: 'project_id',
              isEqualTo: projectId,
              orderBy: 'created_at',
              descending: true)
          .map((rows) {
        return rows.where((f) {
          if (canvasId != null && f.metadata?['canvas_id'] != canvasId)
            return false;
          if (uploadedBy != null && f.createdBy != uploadedBy) return false;
          return true;
        }).toList();
      });
    }
    return _metaRepo.getStream(orderBy: 'created_at', descending: true);
  }

  Future<Uint8List?> downloadFile(String storagePath) =>
      _storageService.downloadFile(storagePath);

  Future<String> getDownloadUrl(String storagePath) =>
      _storageService.getDownloadUrl(storagePath);

  Future<void> deleteFile(String fileId) async {
    final fileMetadata = await getFileMetadata(fileId);
    if (fileMetadata == null) {
      throw Exception('File metadata not found: $fileId');
    }
    await _storageService.deleteFile(fileMetadata.storagePath);
    await _metaRepo.delete(fileId);
  }

  Future<List<String>> deleteMultipleFiles(List<String> fileIds) async {
    final failed = <String>[];
    for (final id in fileIds) {
      try {
        await deleteFile(id);
      } catch (e) {
        debugPrint('Failed to delete file $id: $e');
        failed.add(id);
      }
    }
    return failed;
  }

  Future<bool> fileExists(String storagePath) =>
      _storageService.fileExists(storagePath);

  Future<void> _saveFileMetadata(StorageFile storageFile) async {
    try {
      await _metaRepo.add([storageFile]);
    } catch (e) {
      debugPrint('Error saving storage_files metadata: $e');
      // Best-effort cleanup of the orphaned upload
      try {
        await _storageService.deleteFile(storageFile.storagePath);
      } catch (cleanupError) {
        debugPrint('Cleanup also failed: $cleanupError');
      }
      rethrow;
    }
  }
}

/// Enum for file type filtering
enum StorageFileType {
  image,
  media,
  document,
}
