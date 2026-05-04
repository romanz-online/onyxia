import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:onyxia/export.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthRepository();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
      final user = userCredential.user;
      if (user != null) {
        await _createOrUpdateUserInFirestore(user);
      }
      return user;
    } catch (error) {
      debugPrint('Error signing in with Google: $error');
      return null;
    }
  }

  Future<User?> signInWithFakeAccount() async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: 'narwhalstagingaccount@test.com',
        password: '123456',
      );
      final user = credential.user;
      if (user != null) {
        await _createOrUpdateUserInFirestore(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint(e.toString());
      return null;
    } catch (error) {
      debugPrint('Error signing in with fake account: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      debugPrint('Error signing out: $error');
    }
  }

  Future<void> _createOrUpdateUserInFirestore(User user) async {
    final email = user.email ?? '';

    // Check if a provisional (pending) user exists with this email.
    // If so, reconcile: create the real doc at the Firebase UID, update all
    // project member references to point to the new ID, then delete the provisional doc.
    if (email.isNotEmpty) {
      final pendingQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('pending', isEqualTo: true)
          .limit(1)
          .get();

      if (pendingQuery.docs.isNotEmpty) {
        final provisionalId = pendingQuery.docs.first.id;

        final memberRefs = await FirebaseFirestore.instance
            .collectionGroup('members')
            .where('definitionId', isEqualTo: provisionalId)
            .get();

        final batch = FirebaseFirestore.instance.batch();

        final realUserRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        batch.set(
          realUserRef,
          {
            'id': user.uid,
            'email': email,
            'name': user.displayName ?? '',
            'pending': false,
            'imageUrl': user.photoURL ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        for (final memberRef in memberRefs.docs) {
          batch.update(memberRef.reference, {'definitionId': user.uid});
        }

        batch.delete(pendingQuery.docs.first.reference);

        await batch.commit();
        return;
      }
    }

    // Normal create-or-update flow.
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    final userData = {
      'id': user.uid,
      'email': email,
      'name': user.displayName ?? '',
      'pending': false,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!docSnapshot.exists || !docSnapshot.data()!.containsKey('imageUrl')) {
      userData['imageUrl'] = user.photoURL ?? '';
    }

    await userDoc.set(userData, SetOptions(merge: true));
  }

  User? get currentUser => _auth.currentUser;

  Future<bool> updateUserProfile(UserDefinition user) async {
    try {
      final userData = user.toMap();
      userData['updatedAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection('users').doc(user.id).update(userData);

      final firebaseUser = currentUser;
      if (firebaseUser != null) {
        try {
          await firebaseUser.updateDisplayName(user.name);
        } catch (authError) {
          debugPrint('Could not update Firebase Auth user profile: $authError');
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }
}
