import 'package:onyxia/export.dart';

class User {
  final String id;
  final String name;
  final String email;
  final bool isLogged;

  /// Whether this user has a real account yet. A "ghost" user (`false`) was
  /// added to a vault by email before ever signing up; they become registered
  /// once they create their account with that email.
  final bool isRegistered;

  // Read-only audit fields, populated by the database triggers and parsed in
  // [fromMap]. Never written back (there is no toMap; excluded from copyWith).
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isLogged = false,
    this.isRegistered = false,
    //
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  User.initial()
    : id = '',
      name = 'Anonymous User',
      email = '',
      isLogged = false,
      isRegistered = false,
      //
      createdAt = null,
      createdBy = null,
      updatedAt = null,
      updatedBy = null;

  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? isLogged,
    bool? isRegistered,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    isLogged: isLogged ?? this.isLogged,
    isRegistered: isRegistered ?? this.isRegistered,
  );

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    isRegistered: map['is_registered'] ?? false,
    //
    createdAt: TimestampService.fromMap(map['created_at']),
    createdBy: map['created_by'],
    updatedAt: TimestampService.fromMap(map['updated_at']),
    updatedBy: map['updated_by'],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == id &&
          other.email == email &&
          other.name == name &&
          other.isLogged == isLogged &&
          other.isRegistered == isRegistered &&
          other.createdAt == createdAt &&
          other.createdBy == createdBy &&
          other.updatedAt == updatedAt &&
          other.updatedBy == updatedBy);

  @override
  int get hashCode => Object.hash(
    id,
    email,
    name,
    isLogged,
    isRegistered,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
  );

  @override
  String toString() =>
      'User(id: $id, '
      'name: $name, '
      'email: $email, '
      'isLogged: $isLogged, '
      'isRegistered: $isRegistered, '
      'createdAt: $createdAt, '
      'createdBy: $createdBy, '
      'updatedAt: $updatedAt, '
      'updatedBy: $updatedBy, '
      ')';
}

extension UserInitials on User {
  String get initials {
    if (name.trim().isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts[0][0].toUpperCase() : '';
    final last = parts.length > 1 ? parts[1][0].toUpperCase() : '';
    return first + last;
  }
}
