import 'package:onyxia/export.dart';

class Pins {
  final List<Pin> pins;
  Pins({
    required this.pins,
  });

  factory Pins.initial() {
    return Pins(
      pins: [],
    );
  }

  Pins copyWith({
    List<Pin>? pins,
  }) {
    return Pins(
      pins: pins ?? this.pins,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pins': pins.map((x) => x.toMap()).toList(),
    };
  }

  factory Pins.fromMap(Map<String, dynamic> map) {
    return Pins(
      pins: List<Pin>.from(
        map['pins']?.map((x) => Pin.fromMap(x)) ?? [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Pins.fromJson(String source) => Pins.fromMap(json.decode(source));

  @override
  String toString() => 'Pins('
      'pins: $pins '
      ')';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Pins && listEquals(other.pins, pins);
  }

  @override
  int get hashCode => pins.hashCode;
}
