import 'package:onyxia/export.dart';

final selectedArtifactNameProvider =
    NotifierProvider<SelectedArtifactNameNotifier, String?>(
  SelectedArtifactNameNotifier.new,
);

class SelectedArtifactNameNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final selectedArtifactProvider = Provider<Artifact?>((ref) {
  final name = ref.watch(selectedArtifactNameProvider);
  if (name == null || name.isEmpty) return null;
  return ref
      .watch(artifactsProvider)
      .firstWhereOrNull((a) => a.name == name);
});

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
