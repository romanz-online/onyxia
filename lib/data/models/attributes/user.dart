import 'package:onyxia/export.dart';

class UserDefinition extends AttributeDefinition {
  final String email;
  final bool isLogged;
  final String aboutMe;
  final bool pending;
  final String imageUrl;

  UserDefinition({
    required String id,
    required String name,
    required this.email,
    required this.isLogged,
    this.aboutMe = '',
    this.pending = false,
    this.imageUrl = '',
  }) : super(id: id, name: name);

  UserDefinition.initial()
      : email = '',
        isLogged = false,
        aboutMe = '',
        pending = false,
        imageUrl = '',
        super(id: '', name: 'Anonymous User');

  UserDefinition copyWith({
    String? id,
    String? email,
    String? name,
    bool? isLogged,
    String? aboutMe,
    bool? pending,
    String? imageUrl,
  }) {
    return UserDefinition(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      isLogged: isLogged ?? this.isLogged,
      aboutMe: aboutMe ?? this.aboutMe,
      pending: pending ?? this.pending,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'about_me': aboutMe,
      'image_url': imageUrl,
    };
  }

  factory UserDefinition.fromMap(Map<String, dynamic> map) {
    return UserDefinition(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      isLogged: false,
      aboutMe: map['about_me'] ?? '',
      pending: false,
      imageUrl: map['image_url'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserDefinition.fromJson(String source) => UserDefinition.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AppUser(id: $id, '
        'email: $email, '
        'name: $name, '
        'isLogged: $isLogged, '
        'aboutMe: $aboutMe, '
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserDefinition &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.isLogged == isLogged &&
        other.aboutMe == aboutMe &&
        other.pending == pending;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ name.hashCode ^ isLogged.hashCode ^ aboutMe.hashCode;
  }
}

extension AppUserInitials on UserDefinition {
  String get initials {
    if (name.trim().isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts[0][0].toUpperCase() : '';
    final last = parts.length > 1 ? parts[1][0].toUpperCase() : '';
    return first + last;
  }
}

class UserReference extends AttributeReference {
  final String id; // needs its own beyond definitionId because UserReference maintains its own backing row
  final String definitionId; // = userId
  final UserRole role;

  UserReference({
    id,
    required this.definitionId,
    required this.role,
  }) : id = id ?? const Uuid().v4();

  @override
  Type get definitionType => UserDefinition;

  @override
  UserDefinition? get definition => super.definition as UserDefinition?;

  /// Typed access to the full [UserDefinition] definition.
  ///
  /// Use this to access any AppUser field (email, imageUrl, profileColor, etc.)
  /// without needing a separate provider lookup:
  ///   memberRef.appUser?.email
  ///   memberRef.appUser?.imageUrl
  ///
  /// Returns null if the [ProjectMembersNotifier] hasn't loaded yet.
  UserDefinition? get appUser => definition;

  @override
  bool matchesDefinition(Object other) => other is UserDefinition && definitionId == other.id;

  UserReference copyWith({
    String? id,
    String? definitionId,
    UserRole? role,
  }) =>
      UserReference(
        id: id ?? this.id,
        definitionId: definitionId ?? this.definitionId,
        role: role ?? this.role,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': definitionId,
        'role': role.value,
      };

  static UserReference fromMap(Map<String, dynamic> map) => UserReference(
        id: map['id'] ?? Uuid().v4(),
        definitionId: map['user_id'] ?? '',
        role: UserRole.values.fromString(map['role'] ?? ''),
      );

  @override
  String toString() => 'UserReference(id: $id, '
      'definitionId: $definitionId, '
      'role: ${role.value}, '
      ')';
}
