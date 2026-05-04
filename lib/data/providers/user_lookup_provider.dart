import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onyxia/export.dart';

/// Provider that caches user data by ID to avoid repeated Firestore lookups
final userLookupProvider = Provider<UserLookupService>((ref) => UserLookupService());

class UserLookupService {
  final Map<String, UserDefinition> _userCache = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Gets a user by their ID, using cached data if available.
  /// Returns an AppUser with empty values if user not found or if userId is empty.
  Future<UserDefinition> getUserById(String userId) async {
    // Handle empty userId case
    if (userId.isEmpty) {
      return UserDefinition(
        id: '',
        name: 'Unknown User',
        email: '',
        isLogged: false,
      );
    }

    // Return cached user if available
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        if (userData != null) {
          final user = UserDefinition(
            id: userId,
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            isLogged: false, // Not relevant for other users
            aboutMe: userData['aboutMe'] ?? '',
          );

          // Cache the user data
          _userCache[userId] = user;
          return user;
        }
      }

      return UserDefinition(
        id: userId,
        name: 'Unknown User',
        email: '',
        isLogged: false,
        aboutMe: '',
      );
    } catch (error) {
      debugPrint('Error fetching user $userId: $error');
      return UserDefinition(
        id: userId,
        name: 'Error',
        email: '',
        isLogged: false,
        aboutMe: '',
      );
    }
  }
}
