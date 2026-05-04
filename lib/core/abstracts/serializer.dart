import 'package:onyxia/export.dart';

abstract class Serializer<T> {
  String get projectId;
  String get itemId;
  ArtifactType get itemType;

  Future<void> deserialize(Map<String, dynamic> data);
  Future<Map<String, dynamic>> serialize();
}
