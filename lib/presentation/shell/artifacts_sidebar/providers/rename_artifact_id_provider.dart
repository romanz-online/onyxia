import 'package:onyxia/export.dart';

final renameArtifactIdProvider =
    NotifierProvider<RenameArtifactIdNotifier, String?>(
  RenameArtifactIdNotifier.new,
);

class RenameArtifactIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}
