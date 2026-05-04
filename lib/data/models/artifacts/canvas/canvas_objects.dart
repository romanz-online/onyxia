import 'package:onyxia/export.dart';

class CanvasObjects {
  final List<CanvasObject> objects;
  final List<CanvasObject> selectedObjects;
  CanvasObjects({
    required this.objects,
    required this.selectedObjects,
  });

  factory CanvasObjects.initial() {
    return CanvasObjects(
      objects: [],
      selectedObjects: [],
    );
  }

  CanvasObjects copyWith({
    List<CanvasObject>? objects,
    List<CanvasObject>? selectedObjects,
  }) {
    return CanvasObjects(
      objects: objects ?? this.objects,
      selectedObjects: selectedObjects ?? this.selectedObjects,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'objects': objects.map((x) => x.toMap()).toList(),
      'selectedObjects': selectedObjects.map((x) => x.toMap()).toList(),
    };
  }

  factory CanvasObjects.fromMap(Map<String, dynamic> map) {
    return CanvasObjects(
      objects: List<CanvasObject>.from(map['objects']?.map((x) => CanvasObject.fromMap(x))),
      selectedObjects: map['selectedObjects']?.map((x) => CanvasObject.fromMap(x)),
    );
  }

  String toJson() => json.encode(toMap());

  factory CanvasObjects.fromJson(String source) => CanvasObjects.fromMap(json.decode(source));

  @override
  String toString() => 'Objects(objects: $objects, selectedObjects: $selectedObjects)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CanvasObjects &&
        listEquals(other.objects, objects) &&
        listEquals(other.selectedObjects, selectedObjects);
  }

  @override
  int get hashCode => objects.hashCode ^ selectedObjects.hashCode;
}
