import 'package:onyxia/export.dart';

abstract class ExpandablePin {
  String get id;
  Offset? get position;

  Offset getOffset({CanvasObject? parent});
}
