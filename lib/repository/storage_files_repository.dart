import 'package:onyxia/export.dart';
import 'package:onyxia/data/models/storage_file.dart';

/// Metadata-only repository for the `storage_files` table. The bucket side
/// (uploads/downloads) is handled by `FileStorageService` in
/// `lib/services/supabase_storage_service.dart`.
class StorageFilesRepository extends BaseSupabaseRepository<StorageFile> {
  StorageFilesRepository({super.projectId});

  @override
  String get tableName => 'storage_files';

  @override
  bool get requireProjectId => false;

  @override
  StorageFile fromMap(Map<String, dynamic> map) => StorageFile.fromMap(map);

  @override
  Map<String, dynamic> toMap(StorageFile item) => item.toMap();

  @override
  String getIdFromItem(StorageFile item) => item.id;
}
