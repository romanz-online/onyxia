import 'package:onyxia/export.dart';

/// Reads from the `public.users` view (a thin projection over `auth.users`).
/// The view is read-only — `add` / `update` / `delete` will fail at the DB
/// level by design.
class UsersRepository extends BaseSupabaseRepository<User> {
  UsersRepository();

  @override
  String get tableName => 'users';

  @override
  bool get requireProjectId => false;

  @override
  User fromMap(Map<String, dynamic> map) => User.fromMap(map);

  @override
  Map<String, dynamic> toMap(User item) =>
      throw UnsupportedError('users is a view; writes are not allowed.');

  @override
  String getIdFromItem(User item) => item.id;

  Future<User?> getByEmail(String email) async {
    final results = await query(field: 'email', isEqualTo: email, limit: 1);
    return results.firstOrNull;
  }
}
