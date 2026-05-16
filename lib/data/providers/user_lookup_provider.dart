import 'package:onyxia/export.dart';

// TODO: prime candidate for cutting and just replacing with vault member lookup

/// Caches user data by ID to avoid repeated Supabase lookups.
final userLookupProvider =
    Provider<UserLookupService>((ref) => UserLookupService());

class UserLookupService {
  final Map<String, User> _userCache = {};
  final UsersRepository _repository = UsersRepository();

  /// Returns a User by ID, using the cache when possible. Returns a
  /// placeholder for empty IDs or missing rows so the caller always has
  /// something renderable.
  Future<User> getUserById(String? userId) async {
    if (userId == null || userId.isEmpty) {
      return const User(id: '', name: 'Unknown User', email: '');
    }

    final cached = _userCache[userId];
    if (cached != null) return cached;

    try {
      final user = await _repository.get(userId);
      if (user != null) {
        _userCache[userId] = user;
        return user;
      }
      return User(id: userId, name: 'Unknown User', email: '');
    } catch (error) {
      debugPrint('Error fetching user $userId: $error');
      return User(id: userId, name: 'Error', email: '');
    }
  }
}
