import 'package:onyxia/export.dart';

// TODO: View public.users is defined with the SECURITY DEFINER property

// TODO: View/Materialized View "users" in the public schema may expose auth.users data to anon or authenticated roles.

/// Reads from the `public.users` view (a thin projection over `auth.users`).
/// The view is read-only — `add` / `update` / `delete` will fail at the DB
/// level by design.
class UsersRepository extends BaseSupabaseRepository<User> {
  UsersRepository();

  @override
  String get tableName => 'users';

  @override
  bool get requireVaultId => false;

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
