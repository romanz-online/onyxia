import 'package:onyxia/export.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onyxia/data/models/storage_file.dart';
import 'package:onyxia/services/firebase_storage_service.dart';

/// High-level repository for storage operations
/// Integrates Firebase Storage with Firestore for metadata management
class FileStorage {
  static final FileStorage _instance = FileStorage._internal();
  factory FileStorage() => _instance;
  FileStorage._internal();

  final FileStorageService _storageService = FileStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload a file and save metadata to Firestore
  ///
  /// This method uploads the file to Firebase Storage and saves the metadata
  /// to Firestore for easy querying and management
  ///
  /// Example usage:
  /// ```dart
  /// final storageFile = await FileStorage().uploadFile(
  ///   fileData: selectedFile,
  ///   fileName: 'my-image.jpg',
  ///   mimeType: 'image/jpeg',
  ///   uploadedBy: currentUser.uid,
  ///   projectId: 'project-123',
  ///   folder: 'images',
  ///   onProgress: (progress) => print('Upload progress: ${(progress * 100).toInt()}%'),
  /// );
  /// ```
  Future<StorageFile> uploadFile({
    dynamic fileData, // File, Uint8List, or String (file path)
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
    try {
      // Upload file to Firebase Storage
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

      // Save metadata to Firestore
      await _saveFileMetadata(storageFile);

      return storageFile;
    } catch (e) {
      debugPrint('Error in FileStorage.uploadFile: $e');
      rethrow;
    }
  }

  /// Upload multiple files and save metadata to Firestore
  ///
  /// Example usage:
  /// ```dart
  /// final files = await FileStorage().uploadMultipleFiles(
  ///   fileDataList: [file1, file2, file3],
  ///   fileNames: ['image1.jpg', 'image2.png', 'document.pdf'],
  ///   mimeTypes: ['image/jpeg', 'image/png', 'application/pdf'],
  ///   uploadedBy: currentUser.uid,
  ///   projectId: 'project-123',
  ///   onProgress: (completed, total) => print('$completed/$total files uploaded'),
  /// );
  /// ```
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
    try {
      // Upload files to Firebase Storage
      final storageFiles = await _storageService.uploadMultipleFiles(
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

      // Save all metadata to Firestore in batch
      await _saveMultipleFileMetadata(storageFiles);

      return storageFiles;
    } catch (e) {
      debugPrint('Error in FileStorage.uploadMultipleFiles: $e');
      rethrow;
    }
  }

  /// Get file metadata from Firestore
  ///
  /// Example usage:
  /// ```dart
  /// final fileInfo = await FileStorage().getFileMetadata('file-id-123');
  /// if (fileInfo != null) {
  ///   print('File name: ${fileInfo.name}');
  ///   print('File size: ${fileInfo.formattedSize}');
  /// }
  /// ```
  Future<StorageFile?> getFileMetadata(String fileId) async {
    try {
      final doc = await _firestore.collection('files').doc(fileId).get();

      if (doc.exists && doc.data() != null) {
        return StorageFile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting file metadata: $e');
      return null;
    }
  }

  /// Get files by project ID
  ///
  /// Example usage:
  /// ```dart
  /// final projectFiles = await FileStorage().getFilesByProject('project-123');
  /// for (final file in projectFiles) {
  ///   print('${file.name} - ${file.formattedSize}');
  /// }
  /// ```
  Future<List<StorageFile>> getFilesByProject(String projectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('files')
          .where('projectId', isEqualTo: projectId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => StorageFile.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting files by project: $e');
      return [];
    }
  }

  /// Get files by canvas ID
  ///
  /// Example usage:
  /// ```dart
  /// final canvasFiles = await FileStorage().getFilesByCanvas('project-123', 'canvas-456');
  /// ```
  Future<List<StorageFile>> getFilesByCanvas(String projectId, String canvasId) async {
    try {
      final querySnapshot = await _firestore
          .collection('files')
          .where('projectId', isEqualTo: projectId)
          .where('canvasId', isEqualTo: canvasId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => StorageFile.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting files by canvas: $e');
      return [];
    }
  }

  /// Get files by user ID (uploader)
  ///
  /// Example usage:
  /// ```dart
  /// final userFiles = await FileStorage().getFilesByUser('user-789');
  /// ```
  Future<List<StorageFile>> getFilesByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('files')
          .where('uploadedBy', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => StorageFile.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting files by user: $e');
      return [];
    }
  }

  /// Get files by type (images, videos, documents)
  ///
  /// Example usage:
  /// ```dart
  /// // Get all images in a project
  /// final images = await FileStorage().getFilesByType(
  ///   projectId: 'project-123',
  ///   fileType: FileType.image,
  /// );
  /// ```
  Future<List<StorageFile>> getFilesByType({
    String? projectId,
    String? canvasId,
    required StorageFileType fileType,
  }) async {
    try {
      Query query = _firestore.collection('files');

      // Add filters
      if (projectId != null) {
        query = query.where('projectId', isEqualTo: projectId);
      }
      if (canvasId != null) {
        query = query.where('canvasId', isEqualTo: canvasId);
      }

      // Filter by MIME type based on file type
      List<String> mimeTypes;
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

      query = query.where('mimeType', whereIn: mimeTypes).orderBy('uploadedAt', descending: true);

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) => StorageFile.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting files by type: $e');
      return [];
    }
  }

  /// Stream of files for real-time updates
  ///
  /// Example usage:
  /// ```dart
  /// FileStorage().getFilesStream(projectId: 'project-123').listen((files) {
  ///   print('Files updated: ${files.length} files');
  /// });
  /// ```
  Stream<List<StorageFile>> getFilesStream({
    String? projectId,
    String? canvasId,
    String? uploadedBy,
  }) {
    Query query = _firestore.collection('files');

    // Add filters
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    if (canvasId != null) {
      query = query.where('canvasId', isEqualTo: canvasId);
    }
    if (uploadedBy != null) {
      query = query.where('uploadedBy', isEqualTo: uploadedBy);
    }

    query = query.orderBy('uploadedAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => StorageFile.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  /// Download file data
  ///
  /// Example usage:
  /// ```dart
  /// final fileData = await FileStorage().downloadFile('path/to/file.jpg');
  /// // Use fileData (Uint8List) to display image or save to local storage
  /// ```
  Future<Uint8List?> downloadFile(String storagePath) async {
    return await _storageService.downloadFile(storagePath);
  }

  /// Get download URL for a file
  ///
  /// Example usage:
  /// ```dart
  /// final url = await FileStorage().getDownloadUrl('path/to/file.jpg');
  /// // Use URL in Image.network(url) or similar
  /// ```
  Future<String> getDownloadUrl(String storagePath) async {
    return await _storageService.getDownloadUrl(storagePath);
  }

  /// Delete a file and its metadata
  ///
  /// Example usage:
  /// ```dart
  /// await FileStorage().deleteFile('file-id-123');
  /// ```
  Future<void> deleteFile(String fileId) async {
    try {
      // Get file metadata to get storage path
      final fileMetadata = await getFileMetadata(fileId);
      if (fileMetadata == null) {
        throw Exception('File metadata not found');
      }

      // Delete from Firebase Storage
      await _storageService.deleteFile(fileMetadata.storagePath);

      // Delete metadata from Firestore
      await _firestore.collection('files').doc(fileId).delete();

      debugPrint('File deleted successfully: $fileId');
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  /// Delete multiple files and their metadata
  ///
  /// Example usage:
  /// ```dart
  /// final failedDeletes = await FileStorage().deleteMultipleFiles(['file1', 'file2']);
  /// if (failedDeletes.isNotEmpty) {
  ///   print('Failed to delete: $failedDeletes');
  /// }
  /// ```
  Future<List<String>> deleteMultipleFiles(List<String> fileIds) async {
    final failedDeletes = <String>[];

    for (final fileId in fileIds) {
      try {
        await deleteFile(fileId);
      } catch (e) {
        debugPrint('Failed to delete file $fileId: $e');
        failedDeletes.add(fileId);
      }
    }

    return failedDeletes;
  }

  /// Check if a file exists in storage
  ///
  /// Example usage:
  /// ```dart
  /// final exists = await FileStorage().fileExists('path/to/file.jpg');
  /// ```
  Future<bool> fileExists(String storagePath) async {
    return await _storageService.fileExists(storagePath);
  }

  // Private helper methods

  /// Save file metadata to Firestore
  Future<void> _saveFileMetadata(StorageFile storageFile) async {
    try {
      await _firestore.collection('files').doc(storageFile.id).set(storageFile.toMap());
    } catch (e, stackTrace) {
      debugPrint('Error: $e');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('Stack trace: $stackTrace');

      // Try to clean up the uploaded file if metadata save fails
      debugPrint('Attempting to clean up uploaded file...');
      try {
        await _storageService.deleteFile(storageFile.storagePath);
        debugPrint('File cleanup successful');
      } catch (cleanupError) {
        debugPrint('Error cleaning up file after metadata save failure: $cleanupError');
      }
      rethrow;
    }
  }

  /// Save multiple file metadata to Firestore in batch
  Future<void> _saveMultipleFileMetadata(List<StorageFile> storageFiles) async {
    try {
      final batch = _firestore.batch();

      for (final file in storageFiles) {
        final docRef = _firestore.collection('files').doc(file.id);
        batch.set(docRef, file.toMap());
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error saving multiple file metadata: $e');
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
