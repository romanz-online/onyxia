import 'package:onyxia/export.dart';

enum ArtifactType with NarwhalEnum {
  note,
  canvas,
  folder;

  String get label => switch (this) {
        note => 'Note',
        canvas => 'Canvas',
        folder => 'Folder',
      };
}
