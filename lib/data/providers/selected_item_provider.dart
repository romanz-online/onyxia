import 'package:onyxia/export.dart';

final selectedArtifactProvider =
    NotifierProvider<SelectedArtifactNotifier, Artifact?>(
  SelectedArtifactNotifier.new,
);

class SelectedArtifactNotifier extends Notifier<Artifact?> {
  @override
  Artifact? build() => null;

  void set(Artifact? value) => state = value;
}

enum SaveMode { auto, manual }

final editorSaveModeProvider =
    NotifierProvider<EditorSaveModeNotifier, SaveMode>(
  EditorSaveModeNotifier.new,
);

class EditorSaveModeNotifier extends Notifier<SaveMode> {
  @override
  SaveMode build() => SaveMode.auto;

  void set(SaveMode value) => state = value;
}
