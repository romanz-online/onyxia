import 'package:onyxia/export.dart';

class BrushProperties {
  List<Offset> points;

  BrushProperties({
    this.points = const <Offset>[],
  });

  factory BrushProperties.initial() {
    return BrushProperties(points: []);
  }

  @override
  String toString() {
    return 'BrushProperties('
        'points: $points, '
        ')';
  }

  Map<String, dynamic> toMap() {
    return {'points': points.map((x) => x.toMap()).toList()};
  }

  factory BrushProperties.fromMap(Map<String, dynamic> map) {
    try {
      // Safe points parsing
      List<Offset> points = <Offset>[];
      try {
        if (map['points'] != null) {
          points = List<Offset>.from(
              map['points'].map((x) => OffsetExtension.fromMap(x)));
        }
      } catch (e) {
        points = <Offset>[];
      }

      return BrushProperties(points: points);
    } catch (e) {
      // Return a completely default BrushProperties if parsing fails entirely
      return BrushProperties();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BrushProperties && listEquals(other.points, points);
  }

  @override
  int get hashCode {
    return points.hashCode;
  }
}
