import 'package:onyxia/export.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, UserDefinition>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return CurrentUserNotifier(authRepository);
});

class CurrentUserNotifier extends StateNotifier<UserDefinition> {
  final AuthRepository repository;

  // True while signInWithGoogle() is awaiting repository.signInWithGoogle()
  // (which includes the reconciliation batch). Suppresses _listenToAuthChanges
  // from setting currentUser.id prematurely, preventing projectsProvider from
  // querying projects before the reconciliation batch commits.
  bool _signingIn = false;

  CurrentUserNotifier(this.repository) : super(UserDefinition.initial()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    // Listen to user auth changes
    repository.authStateChanges.listen((user) {
      if (_signingIn) return; // Skip during active Google sign-in; signInWithGoogle() sets state after reconciliation
      if (user != null) {
        // Get the updated user data from Firestore instead of directly using Firebase Auth data
        // This ensures we get the latest custom imageUrl if it exists
        _loadUserDataFromFirestore(user.uid);
      } else {
        state = UserDefinition.initial();
      }
    });
  }

  /// Helper method to update user state from Firestore data
  void _updateUserState(String userId, Map<String, dynamic> userData) {
    final firebaseUser = repository.currentUser;

    String? _getValidString(String? value) => (value == null || value.isEmpty) ? null : value;

    state = state.copyWith(
      id: userId,
      name: _getValidString(userData['name']) ?? _getValidString(firebaseUser?.displayName) ?? 'Anon A. Moose',
      email: userData['email'] ?? firebaseUser?.email ?? '',
      aboutMe: userData['aboutMe'] ?? '',
      isLogged: true,
    );
  }

  /// Loads the user data from Firestore to get the most up-to-date information
  Future<void> _loadUserDataFromFirestore(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          _updateUserState(userId, userData);
        }
      } else {
        // Fallback to Firebase Auth data if Firestore document doesn't exist
        final firebaseUser = repository.currentUser;
        if (firebaseUser != null) {
          state = state.copyWith(
            id: firebaseUser.uid,
            name: firebaseUser.displayName,
            email: firebaseUser.email,
            isLogged: true,
          );
        }
      }
    } catch (error) {
      debugPrint('Error loading user data from Firestore: $error');

      // Fallback to Firebase Auth data if there's an error
      final firebaseUser = repository.currentUser;
      if (firebaseUser != null) {
        state = state.copyWith(
          id: firebaseUser.uid,
          name: firebaseUser.displayName,
          email: firebaseUser.email,
          isLogged: true,
        );
      }
    }
  }

  Future<void> signOut() async {
    try {
      await repository.signOut();
    } catch (error) {
      debugPrint('Error signing out: $error');
    }
  }

  Future<bool> signInWithGoogle() async {
    _signingIn = true;
    try {
      // Google log in — awaits reconciliation inside repository.signInWithGoogle()
      final user = await repository.signInWithGoogle();
      if (user != null) {
        state = state.copyWith(
          id: user.uid,
          name: user.displayName,
          email: user.email,
          isLogged: true,
        );
        return true;
      }
      return false;
    } finally {
      _signingIn = false;
    }
  }

  Future<bool> signInWithFakeAccount() async {
    final user = await repository.signInWithFakeAccount();
    if (user != null) {
      // State will be updated via _listenToAuthChanges
      return true;
    }
    return false;
  }

  /// Updates the user's complete profile
  Future<void> updateUserProfile(UserDefinition updatedUser) async {
    try {
      // Update in Firebase
      final result = await repository.updateUserProfile(updatedUser);

      if (result) {
        // Update the local state
        state = updatedUser;

        // Refresh user data from Firestore to ensure we have the latest
        await _loadUserDataFromFirestore(updatedUser.id);
      } else {
        debugPrint('Failed to update user profile in Firebase');
      }
    } catch (error) {
      debugPrint('Error updating user profile: $error');
    }
  }
}
