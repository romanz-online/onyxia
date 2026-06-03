class User {
  final String id;
  final String name;
  final String email;
  final bool isLogged;

  /// Whether this user has a real account yet. A "ghost" user (`false`) was
  /// added to a vault by email before ever signing up; they become registered
  /// once they create their account with that email.
  final bool isRegistered;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isLogged = false,
    this.isRegistered = false,
  });

  User.initial()
    : id = '',
      name = 'Anonymous User',
      email = '',
      isLogged = false,
      isRegistered = false;

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
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == id &&
          other.email == email &&
          other.name == name &&
          other.isLogged == isLogged &&
          other.isRegistered == isRegistered);

  @override
  int get hashCode => Object.hash(id, email, name, isLogged, isRegistered);

  @override
  String toString() =>
      'User(id: $id, '
      'name: $name, '
      'email: $email, '
      'isLogged: $isLogged, '
      'isRegistered: $isRegistered, '
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
