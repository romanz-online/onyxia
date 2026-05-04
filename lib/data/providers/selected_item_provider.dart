import 'package:onyxia/export.dart';

final selectedArtifactProvider = StateProvider<Artifact?>((ref) => null);

enum SaveMode { auto, manual }

final editorSaveModeProvider = StateProvider<SaveMode>((ref) => SaveMode.auto);

/// The child item selected within the folder editor preview panel.
final selectedFolderChildArtifactProvider = StateProvider<Artifact?>((ref) => null);
