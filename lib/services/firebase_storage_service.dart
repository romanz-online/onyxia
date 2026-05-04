import 'dart:io';
import 'package:onyxia/export.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:onyxia/data/models/storage_file.dart';
import 'package:path/path.dart' as path;

/// Service for handling Firebase Storage operations
/// Provides methods for uploading, downloading, deleting, and managing files
class FileStorageService {
  static final FileStorageService _instance = FileStorageService._internal();
  factory FileStorageService() => _instance;
  FileStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const Uuid _uuid = Uuid();

  // File size limits (in bytes)
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxMediaSize = 100 * 1024 * 1024; // 100MB
  static const int maxDocumentSize = 50 * 1024 * 1024; // 50MB
  static const int maxAudioSize = 50 * 1024 * 1024; // 50MB

  // Allowed file types
  static const List<String> allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
  static const List<String> allowedMediaTypes = [
    'video/mp4',
    'video/avi',
    'video/mov',
    'video/wmv',
    'video/webm',
    'video/quicktime',
    'video/x-msvideo',
    'video/x-matroska'
  ];
  static const List<String> allowedAudioTypes = [
    'audio/mpeg',
    'audio/wav',
    'audio/ogg',
    'audio/mp4',
    'audio/aac',
    'audio/flac',
    'audio/x-flac'
  ];
  static const List<String> allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
    'text/csv',
    'text/markdown',
    'text/html',
    'application/rtf',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  ];

  /// Upload a file to Firebase Storage
  ///
  /// [fileData] - The file data as Uint8List (for web) or File path
  /// [fileName] - Original filename
  /// [mimeType] - MIME type of the file
  /// [uploadedBy] - User ID of the uploader
  /// [projectId] - Optional project ID for organization
  /// [canvasId] - Optional canvas ID for organization
  /// [folder] - Optional custom folder path (e.g., 'images', 'documents')
  /// [onProgress] - Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns a [StorageFile] object with file metadata and download URL
  Future<StorageFile> uploadFile({
    dynamic fileData, // Can be File, Uint8List, or String (file path)
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
      // Validate file type and size
      _validateFile(mimeType, fileData);

      // Generate unique file ID and path
      final fileId = _uuid.v4();

      final storagePath = _buildStoragePath(
        fileId: fileId,
        fileName: fileName,
        projectId: projectId,
        canvasId: canvasId,
        userId: userId,
        folderId: folderId,
        folder: folder,
      );
      // Create storage reference
      final ref = _storage.ref().child(storagePath);

      // Prepare upload task based on file data type
      UploadTask uploadTask;
      int fileSize = 0;

      if (fileData is Uint8List) {
        // Upload using Uint8List (works on all platforms)
        fileSize = fileData.length;
        uploadTask = ref.putData(
          fileData,
          SettableMetadata(
            contentType: mimeType,
            customMetadata: {
              'uploadedBy': uploadedBy,
              'originalName': fileName,
              'fileId': fileId,
              ...?metadata,
            },
          ),
        );
      } else if (fileData is File) {
        // Mobile/Desktop upload using File (fallback for direct file uploads)
        fileSize = await fileData.length();
        uploadTask = ref.putFile(
          fileData,
          SettableMetadata(
            contentType: mimeType,
            customMetadata: {
              'uploadedBy': uploadedBy,
              'originalName': fileName,
              'fileId': fileId,
              ...?metadata,
            },
          ),
        );
      } else {
        throw ArgumentError('Unsupported file data type. Use File for mobile/desktop or Uint8List for web.');
      }

      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for upload completion
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Create and return StorageFile object
      final storageFile = StorageFile(
        id: fileId,
        name: fileName,
        storagePath: storagePath,
        downloadUrl: downloadUrl,
        sizeBytes: fileSize,
        mimeType: mimeType,
        uploadedAt: DateTime.now(),
        uploadedBy: uploadedBy,
        projectId: projectId,
        metadata: metadata,
      );
      return storageFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload multiple files concurrently
  ///
  /// Returns a list of [StorageFile] objects for successfully uploaded files
  /// Failed uploads will throw exceptions - handle them individually if needed
  Future<List<StorageFile>> uploadMultipleFiles({
    required List<dynamic> fileDataList, // List of File or Uint8List
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

    final List<Future<StorageFile>> uploadFutures = [];

    for (int i = 0; i < fileDataList.length; i++) {
      uploadFutures.add(
        uploadFile(
          fileData: fileDataList[i],
          fileName: fileNames[i],
          mimeType: mimeTypes[i],
          uploadedBy: uploadedBy,
          projectId: projectId,
          canvasId: canvasId,
          folder: folder,
          metadata: metadata,
        ),
      );
    }

    // Execute uploads concurrently and track progress
    final results = <StorageFile>[];
    int completed = 0;

    for (final future in uploadFutures) {
      try {
        final result = await future;
        results.add(result);
        completed++;
        onProgress?.call(completed, uploadFutures.length);
      } catch (e) {
        completed++;
        onProgress?.call(completed, uploadFutures.length);
        rethrow; // Re-throw to let caller handle individual failures
      }
    }

    return results;
  }

  /// Download a file as bytes
  ///
  /// [storagePath] - Full path to the file in Firebase Storage
  /// [maxSize] - Maximum size to download (default 10MB)
  ///
  /// Returns the file data as Uint8List
  Future<Uint8List?> downloadFile(
    String storagePath, {
    int maxSize = 10 * 1024 * 1024,
  }) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getData(maxSize);
    } catch (e) {
      rethrow;
    }
  }

  /// Get download URL for a file
  ///
  /// [storagePath] - Full path to the file in Firebase Storage
  ///
  /// Returns the download URL as String
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a file from Firebase Storage
  ///
  /// [storagePath] - Full path to the file in Firebase Storage
  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete multiple files
  ///
  /// [storagePaths] - List of full paths to files in Firebase Storage
  ///
  /// Returns a list of paths that failed to delete (empty if all successful)
  Future<List<String>> deleteMultipleFiles(List<String> storagePaths) async {
    final failedDeletes = <String>[];

    for (final path in storagePaths) {
      try {
        await deleteFile(path);
      } catch (e) {
        failedDeletes.add(path);
      }
    }

    return failedDeletes;
  }

  /// List files in a specific folder
  ///
  /// [folderPath] - Path to the folder (e.g., 'projects/project1/images')
  /// [maxResults] - Maximum number of results to return
  ///
  /// Returns a list of file references
  Future<List<Reference>> listFiles(String folderPath, {int maxResults = 100}) async {
    try {
      final ref = _storage.ref().child(folderPath);
      final result = await ref.listAll();
      return result.items;
    } catch (e) {
      rethrow;
    }
  }

  /// Get file metadata
  ///
  /// [storagePath] - Full path to the file in Firebase Storage
  ///
  /// Returns file metadata
  Future<FullMetadata> getFileMetadata(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getMetadata();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a file exists
  ///
  /// [storagePath] - Full path to the file in Firebase Storage
  ///
  /// Returns true if file exists, false otherwise
  Future<bool> fileExists(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Private helper methods

  /// Validate file type and size
  void _validateFile(String mimeType, dynamic fileData) {
    // Validate file type
    final isValidType = allowedImageTypes.contains(mimeType) ||
        allowedMediaTypes.contains(mimeType) ||
        allowedAudioTypes.contains(mimeType) ||
        allowedDocumentTypes.contains(mimeType);

    if (!isValidType) {
      throw ArgumentError('Unsupported file type: $mimeType');
    }

    // Get file size
    int fileSize = 0;
    if (fileData is Uint8List) {
      fileSize = fileData.length;
    } else if (fileData is File) {
      fileSize = fileData.lengthSync();
    }

    // Validate file size based on type
    if (allowedImageTypes.contains(mimeType) && fileSize > maxImageSize) {
      throw ArgumentError('Image file too large. Maximum size: ${maxImageSize ~/ (1024 * 1024)}MB');
    } else if (allowedMediaTypes.contains(mimeType) && fileSize > maxMediaSize) {
      throw ArgumentError('Media file too large. Maximum size: ${maxMediaSize ~/ (1024 * 1024)}MB');
    } else if (allowedAudioTypes.contains(mimeType) && fileSize > maxAudioSize) {
      throw ArgumentError('Audio file too large. Maximum size: ${maxAudioSize ~/ (1024 * 1024)}MB');
    } else if (allowedDocumentTypes.contains(mimeType) && fileSize > maxDocumentSize) {
      throw ArgumentError('Document file too large. Maximum size: ${maxDocumentSize ~/ (1024 * 1024)}MB');
    }
  }

  /// Build storage path for file organization
  String _buildStoragePath({
    required String fileId,
    required String fileName,
    String? projectId,
    String? canvasId,
    String? userId,
    String? folderId,
    String? folder,
  }) {
    final List<String> pathParts = [];

    // Determine base path based on userId or projectId
    if (userId != null) {
      // User-scoped files (e.g., avatars)
      pathParts.add('users');
      pathParts.add(userId);
    } else if (projectId != null) {
      // Project-scoped files
      pathParts.add('projects');
      pathParts.add(projectId);
    } else {
      // General files (fallback)
      pathParts.add('general');
    }

    // Add specific organizational folders
    if (canvasId != null) {
      // Canvas images: differentiate between whiteboard and markup
      pathParts.add('userExperience');
      pathParts.add(canvasId);
    } else if (folderId != null) {
      // Folder-based markup canvases
      pathParts.add('userExperience');
      pathParts.add('markup');
      pathParts.add(folderId);
    } else if (folder == 'file-uploads') {
      // Individual file uploads: userExperience/markup/file-upload/{fileId}/images/
      pathParts.add('userExperience');
      pathParts.add('markup');
      pathParts.add('file-upload');
      pathParts.add(fileId);
    }

    // Add folder organization (but skip if we already handled file-uploads above)
    if (folder != null && folder != 'file-uploads') {
      pathParts.add(folder);
    } else if (folder == null) {
      pathParts.add('files');
    } else if (folder == 'file-uploads') {
      // For file-uploads, we already added the structure above, just add 'images'
      pathParts.add('images');
    }

    // Add timestamped filename with unique ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(fileName);
    final baseName = path.basenameWithoutExtension(fileName);
    final uniqueFileName = '${timestamp}_${fileId}_$baseName$extension';

    pathParts.add(uniqueFileName);

    return pathParts.join('/');
  }
}
