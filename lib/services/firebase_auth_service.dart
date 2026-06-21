import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

/// Handles Firebase Authentication and Firestore user profile fetching.
/// Passwords are NEVER stored or compared in plain text — Firebase Auth handles
/// credential verification exclusively.
class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _auth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;

  User? get currentUser => _currentUser;

  // ──────────────────────────────────────────────────────────────────────────
  // Login
  // ──────────────────────────────────────────────────────────────────────────

  /// Signs in an admin/owner/super-admin user.
  ///
  /// [usernameOrEmail] can be either a Firestore `username` or `email`.
  /// Passwords are validated purely by Firebase Auth — no plain-text comparison.
  Future<bool> login(String usernameOrEmail, String password) async {
    try {
      // ── Step 1: resolve email from username ─────────────────────────────
      String email;

      if (_looksLikeEmail(usernameOrEmail)) {
        email = usernameOrEmail.trim();
      } else {
        // Look up by username field (exact match first)
        var byUsername = await _firestore
            .collection('users')
            .where('username', isEqualTo: usernameOrEmail.trim())
            .limit(1)
            .get();

        // If exact match fails, try case-insensitive lookup
        if (byUsername.docs.isEmpty) {
          debugPrint('FirebaseAuthService: exact username not found, trying case-insensitive...');
          final allUsers = await _firestore.collection('users').get();
          final inputLower = usernameOrEmail.trim().toLowerCase();
          
          for (var doc in allUsers.docs) {
            final docUsername = (doc.data()['username'] as String? ?? '').toLowerCase();
            if (docUsername == inputLower) {
              // Found a case-insensitive match
              byUsername = await _firestore
                  .collection('users')
                  .where('email', isEqualTo: doc.data()['email'])
                  .limit(1)
                  .get();
              break;
            }
          }
        }

        if (byUsername.docs.isEmpty) {
          debugPrint('FirebaseAuthService: username not found: $usernameOrEmail');
          return false;
        }

        final emailField = byUsername.docs.first.data()['email'] as String?;
        if (emailField == null || emailField.isEmpty) {
          debugPrint('FirebaseAuthService: user document missing email');
          return false;
        }
        email = emailField.trim();
      }

      // ── Step 2: Firebase Auth sign-in ────────────────────────────────────
      bool authSuccess = false;
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        authSuccess = credential.user != null;
      } on firebase_auth.FirebaseAuthException catch (e) {
        debugPrint('FirebaseAuthService: FirebaseAuthException — ${e.code}: ${e.message}');

        if (e.code == 'user-not-found') {
          // User doesn't exist in Firebase Auth — create account (legacy migration)
          authSuccess = await _tryCreateAuthAccount(email, password);
        } else if (e.code == 'invalid-credential') {
          // In newer Firebase Auth SDKs, 'invalid-credential' can mean either
          // "wrong password" or "user not found". Try creating an account:
          // - If it succeeds → the user had no Auth account (legacy migration)
          // - If it fails with 'email-already-in-use' → wrong password
          authSuccess = await _tryCreateAuthAccount(email, password);
        } else if (e.code == 'wrong-password') {
          debugPrint('FirebaseAuthService: wrong password for $email');
          return false;
        } else {
          return false;
        }
      } catch (e) {
        // Some plugins incorrectly throw even on success; check current user.
        await Future.delayed(const Duration(milliseconds: 100));
        authSuccess = _auth.currentUser != null;
      }

      if (!authSuccess) return false;

      // ── Step 3: fetch Firestore profile ──────────────────────────────────
      final profile = await _fetchUserProfile(email);
      if (profile == null) {
        debugPrint('FirebaseAuthService: no Firestore profile for $email');
        return false;
      }

      _currentUser = profile;
      debugPrint('FirebaseAuthService: login OK — ${_currentUser!.username} (${_currentUser!.role})');
      return true;
    } catch (e) {
      debugPrint('FirebaseAuthService: unexpected login error — $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Session
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  /// Re-validates the current Firebase Auth session and reloads the profile.
  Future<bool> checkAuth() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        _currentUser = null;
        return false;
      }

      final profile = await _fetchUserProfile(firebaseUser.email ?? '');
      if (profile != null) {
        _currentUser = profile;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('FirebaseAuthService: checkAuth error — $e');
      _currentUser = null;
      return false;
    }
  }

  Future<bool> loadUserData() async => checkAuth();

  // ──────────────────────────────────────────────────────────────────────────
  // Password Reset
  // ──────────────────────────────────────────────────────────────────────────

  /// Sends a Firebase password-reset email. Returns an error message on
  /// failure, or null on success.
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // success
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email address.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        default:
          return e.message ?? 'Failed to send reset email.';
      }
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  Future<User?> _fetchUserProfile(String email) async {
    if (email.isEmpty) return null;
    try {
      final q = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (q.docs.isEmpty) return null;
      final doc = q.docs.first;
      return User.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      debugPrint('FirebaseAuthService: _fetchUserProfile error — $e');
      return null;
    }
  }

  /// Attempts to create a Firebase Auth account for a user that exists
  /// in Firestore but has no Firebase Auth entry (legacy migration).
  Future<bool> _tryCreateAuthAccount(String email, String password) async {
    try {
      final newCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('FirebaseAuthService: created new Firebase Auth account for $email');
      return newCred.user != null;
    } catch (createErr) {
      debugPrint('FirebaseAuthService: could not create account — $createErr');
      return false;
    }
  }

  bool _looksLikeEmail(String s) => s.contains('@');
}
