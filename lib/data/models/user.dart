class User {
  final String id;
  final String name;
  final String email;
  final bool isLogged;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isLogged = false,
  });

  User.initial()
    : id = '',
      name = 'Anonymous User',
      email = '',
      isLogged = false;

  User copyWith({String? id, String? name, String? email, bool? isLogged}) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        isLogged: isLogged ?? this.isLogged,
      );

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    email: map['email'] ?? '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == id &&
          other.email == email &&
          other.name == name &&
          other.isLogged == isLogged);

  @override
  int get hashCode => Object.hash(id, email, name, isLogged);

  @override
  String toString() =>
      'User(id: $id, '
      'name: $name, '
      'email: $email, '
      'isLogged: $isLogged, '
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
