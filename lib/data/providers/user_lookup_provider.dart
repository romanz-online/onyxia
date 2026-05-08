import 'package:onyxia/export.dart';

/// Caches user data by ID to avoid repeated Supabase lookups.
final userLookupProvider = Provider<UserLookupService>((ref) => UserLookupService());

class UserLookupService {
  final Map<String, UserDefinition> _userCache = {};
  final UserDefinitionsRepository _repository = UserDefinitionsRepository();

  /// Returns a UserDefinition by ID, using the cache when possible. Returns a
  /// placeholder UserDefinition for empty IDs or missing rows so the caller
  /// always has something renderable.
  Future<UserDefinition> getUserById(String userId) async {
    if (userId.isEmpty) {
      return UserDefinition(
        id: '',
        name: 'Unknown User',
        email: '',
        isLogged: false,
      );
    }

    final cached = _userCache[userId];
    if (cached != null) return cached;

    try {
      final user = await _repository.get(userId);
      if (user != null) {
        _userCache[userId] = user;
        return user;
      }
      return UserDefinition(
        id: userId,
        name: 'Unknown User',
        email: '',
        isLogged: false,
      );
    } catch (error) {
      debugPrint('Error fetching user $userId: $error');
      return UserDefinition(
        id: userId,
        name: 'Error',
        email: '',
        isLogged: false,
      );
    }
  }
}
