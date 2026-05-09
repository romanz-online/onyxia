import 'package:onyxia/export.dart';

final selectedArtifactProvider = StateProvider<Artifact?>((ref) => null);

enum SaveMode { auto, manual }

final editorSaveModeProvider = StateProvider<SaveMode>((ref) => SaveMode.auto);
