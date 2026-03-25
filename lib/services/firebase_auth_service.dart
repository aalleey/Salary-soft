import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<bool> login(String usernameOrEmail, String password) async {
    try {
      // Try to find user by username first
      var userQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: usernameOrEmail)
          .limit(1)
          .get();

      // If not found by username, try by email
      if (userQuery.docs.isEmpty) {
        print('User not found by username, trying email...');
        userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: usernameOrEmail)
            .limit(1)
            .get();
      }

      if (userQuery.docs.isEmpty) {
        print(
          'Firestore: User with username/email \'$usernameOrEmail\' not found.',
        );
        return false;
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final email = userData['email'] as String?;
      final storedPassword = userData['password'] as String?;

      if (email == null || storedPassword == null) {
        print('Firestore: User document is missing email or password.');
        return false;
      }

      if (storedPassword != password) {
        print('Firestore: Password does not match.');
        return false;
      }

      print(
        'Firestore password check passed. Trying to sign in with Firebase Auth...',
      );

      // Try Firebase Auth sign in
      bool authSuccess = false;
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        authSuccess = userCredential.user != null;
      } catch (authError) {
        print('Firebase Auth error: $authError');

        // Check if it's an "invalid credential" error - user doesn't exist in Firebase Auth
        final errorString = authError.toString();
        if (errorString.contains('invalid-credential') ||
            errorString.contains('user-not-found')) {
          print(
            'User exists in Firestore but not Firebase Auth. Creating Firebase Auth account...',
          );

          try {
            // Create the user in Firebase Auth
            final newUserCredential = await _auth
                .createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );
            authSuccess = newUserCredential.user != null;
            print('Firebase Auth account created successfully!');
          } catch (createError) {
            print('Failed to create Firebase Auth account: $createError');
            // If email already exists in Auth but with different password, fail
            return false;
          }
        } else {
          // Wait briefly for Firebase to update internal state after plugin error
          await Future.delayed(const Duration(milliseconds: 100));
          // Check if user is actually signed in despite the error (plugin bug)
          authSuccess = _auth.currentUser != null;
        }
      }

      if (!authSuccess) {
        print('Firebase Auth: Authentication failed');
        return false;
      }

      print('Firebase Auth successful! Creating user object...');
      _currentUser = User.fromFirestore(userData, userDoc.id);
      print('Login successful!');
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message} (Code: ${e.code})');
      return false;
    } catch (e) {
      print('An unexpected login error occurred: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  Future<bool> checkAuth() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        _currentUser = null;
        return false;
      }

      // Correctly find the user by email instead of mismatched ID
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: firebaseUser.email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        _currentUser = User.fromFirestore(userDoc.data(), userDoc.id);
        return true;
      }

      return false;
    } catch (e) {
      print('Auth check error: $e');
      _currentUser = null;
      return false;
    }
  }

  Future<bool> loadUserData() async {
    return await checkAuth();
  }
}
