import 'dart:ui';

extension OffsetExtension on Offset {
  Map<String, dynamic> toMap() {
    return {'x': dx, 'y': dy};
  }

  static Offset fromMap(Map<String, dynamic> map) {
    return Offset(map['x'].toDouble(), map['y'].toDouble());
  }

  double dot(Offset other) {
    return dx * other.dx + dy * other.dy;
  }

  Offset normalized() {
    final magnitude = distance;
    if (magnitude == 0) return .zero;
    return Offset(dx / magnitude, dy / magnitude);
  }
}
