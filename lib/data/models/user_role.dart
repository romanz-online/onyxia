import 'package:onyxia/export.dart';

enum UserRole with NarwhalEnum {
  member,
  admin,
  owner;

  String get label => switch (this) {
        UserRole.member => 'Member',
        UserRole.admin => 'Admin',
        UserRole.owner => 'Owner',
      };
}
