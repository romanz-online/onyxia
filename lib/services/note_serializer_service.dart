import 'package:onyxia/export.dart';

class NoteSerializerService extends Serializer<Note> {
  @override
  final String projectId;
  @override
  final String itemId;
  final ArtifactsRepository repository;

  NoteSerializerService({
    required this.projectId,
    required this.itemId,
    required this.repository,
  });

  @override
  ArtifactType get itemType => ArtifactType.note;

  @override
  Future<Map<String, dynamic>> serialize() async {
    try {
      final artifact = await repository.getDocumentStream(itemId).first;

      if (artifact == null) {
        throw Exception('Trace item with id $itemId not found in project $projectId');
      }

      return artifact.toMap();
    } catch (e) {
      throw Exception('Failed to serialize note $itemId: $e');
    }
  }

  @override
  Future<void> deserialize(Map<String, dynamic> data) async {
    _validateData(data);

    try {
      await repository.update(Note.fromMap(data));
    } catch (e) {
      throw Exception('Failed to deserialize and update note $itemId: $e');
    }
  }

  void _validateData(Map<String, dynamic> data) {
    if (data.isEmpty) {
      throw FormatException('Missing required data. Data: $data');
    }

    if (!data.containsKey('title') || data['title'] == null || data['title'].toString().isEmpty) {
      throw FormatException('Missing required field: title. Data: $data');
    }
  }
}
