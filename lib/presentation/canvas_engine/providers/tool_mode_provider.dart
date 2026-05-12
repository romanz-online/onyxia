import 'package:onyxia/export.dart';

enum ToolMode {
  pointer,
  pan,

  // shapes
  rectangle,
  diamond,
  oblong,
  circle,
  rhombus,
  trapezoid,
  cylinder,
  house,
  reverseHouse,

  text,

  image,

  media,

  comment,
  artifact,

  brush,

  arrow,
}

final toolModeProvider =
    NotifierProvider.autoDispose<ToolModeNotifier, ToolMode>(
  ToolModeNotifier.new,
);

class ToolModeNotifier extends Notifier<ToolMode> {
  @override
  ToolMode build() => ToolMode.pointer;

  void set(ToolMode value) => state = value;
}
