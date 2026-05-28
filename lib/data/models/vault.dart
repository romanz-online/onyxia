import 'package:onyxia/export.dart';

class Vault {
  final String id;
  final String name;
  //
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  Vault({
    String? id,
    required this.name,
    //
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  }) : this.id = id == null || id.isEmpty ? const Uuid().v4() : id;

  Vault copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vault(id: id ?? this.id, name: name ?? this.name);
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  Vault.fromMap(Map<String, dynamic> map)
    : id = map['id'] ?? '',
      name = map['name'] ?? '',
      //
      createdAt = TimestampService.fromMap(map['created_at']),
      createdBy = map['created_by'] ?? '',
      updatedAt = TimestampService.fromMap(map['updated_at']),
      updatedBy = map['updated_by'] ?? '';

  @override
  String toString() {
    return 'Vault(id: $id, '
        'createdBy: $createdBy, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'name: $name, '
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Vault &&
        other.id == id &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        createdBy.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        name.hashCode;
  }
}
