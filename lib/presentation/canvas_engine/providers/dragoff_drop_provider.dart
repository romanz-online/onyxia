import 'package:onyxia/export.dart';

final dragOffDropPositionProvider =
    NotifierProvider.autoDispose<DragOffDropPositionNotifier, Offset?>(
  DragOffDropPositionNotifier.new,
);

class DragOffDropPositionNotifier extends Notifier<Offset?> {
  @override
  Offset? build() => null;

  void set(Offset? value) => state = value;
}
