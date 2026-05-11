import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:onyxia/helpers/offset_extension.dart';

class UserCursor {
  final String userId;
  final String userEmail;
  final Offset position;
  final Color color;

  UserCursor({
    required this.userId,
    required this.userEmail,
    required this.position,
    required this.color,
  });

  UserCursor copyWith({
    String? userId,
    String? userEmail,
    Offset? position,
    Color? color,
  }) {
    return UserCursor(
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      position: position ?? this.position,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'position': position.toMap(),
      'color': color.toARGB32(),
    };
  }

  factory UserCursor.fromMap(Map<String, dynamic> map) {
    return UserCursor(
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      position: OffsetExtension.fromMap(map['position']),
      color: Color(map['color']),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserCursor.fromJson(String source) =>
      UserCursor.fromMap(json.decode(source));

  @override
  String toString() =>
      'UserCursor(userId: $userId, userEmail: $userEmail, position: $position, color: $color)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserCursor &&
        other.userId == userId &&
        other.userEmail == userEmail &&
        other.position == position &&
        other.color == color;
  }

  @override
  int get hashCode =>
      userId.hashCode ^ userEmail.hashCode ^ position.hashCode ^ color.hashCode;
}
