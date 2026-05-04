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

final toolModeProvider = StateProvider.autoDispose<ToolMode>((ref) => ToolMode.pointer);
