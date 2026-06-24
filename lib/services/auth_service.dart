import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'firebase_auth_service.dart';
import 'firestore_user_service.dart';

class AuthService {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreUserService _userService = FirestoreUserService();
  
  User? _currentUser;

  User? get currentUser => _currentUser;

  /// Performs login, resolving usernames, checking legacy credentials, and auto-migrating if necessary.
  Future<bool> login(String usernameOrEmail, String password) async {
    try {
      debugPrint('AuthService: Login attempt for "$usernameOrEmail"');
      
      // 1. Resolve identifier to a user email address in Firestore
      String email = usernameOrEmail.trim();
      final resolvedDoc = await _userService.getUserByIdentifier(usernameOrEmail);
      if (resolvedDoc != null) {
        final data = resolvedDoc.data();
        if (data != null && data['email'] != null) {
          email = data['email'];
          debugPrint('AuthService: Resolved identifier to email "$email"');
        }
      } else {
        debugPrint('AuthService: No matching Firestore profile found for identifier "$usernameOrEmail"');
      }

      // 2. Try to log in with Firebase Auth
      auth.UserCredential? userCredential;
      try {
        if (email.contains('@')) {
          userCredential = await _authService.signIn(email, password);
        } else {
          throw auth.FirebaseAuthException(
            code: 'invalid-email',
            message: 'The email address is badly formatted.',
          );
        }
      } on auth.FirebaseAuthException catch (e) {
        debugPrint('AuthService: FirebaseAuthException code=${e.code}, message=${e.message}');
        
        // Handle auto-migration if credentials are valid but user is not in Firebase Auth
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password' || e.code == 'invalid-email') {
          debugPrint('AuthService: Querying profile data to check for auto-migration...');
          
          if (resolvedDoc != null) {
            final data = resolvedDoc.data();
            final userEmail = data != null ? data['email'] as String? : null;
            
            debugPrint('AuthService: Checking password match for "$usernameOrEmail"...');
            if (data != null && data['password'] == password) {
              if (userEmail != null && userEmail.contains('@')) {
                debugPrint('AuthService: Password matches. Auto-migrating user "$userEmail" to Firebase Auth...');
                userCredential = await _authService.signUp(userEmail, password);
                email = userEmail;
              } else {
                throw Exception('User has no valid email address associated.');
              }
            } else {
              debugPrint('AuthService: Password mismatch');
              throw Exception('Invalid credentials. Please check your password.');
            }
          } else {
            debugPrint('AuthService: User not found in Firestore collection');
            throw Exception('User not found. Please check your credentials.');
          }
        } else {
          throw Exception(e.message ?? 'Authentication failed');
        }
      }

      debugPrint('AuthService: Login successful in Firebase Auth');
      
      if (userCredential.user != null) {
        // 3. Fetch user profile from Firestore by UID
        DocumentSnapshot<Map<String, dynamic>> profileDoc = await _userService.getUserByUid(userCredential.user!.uid);
        
        // If not found by UID (created via old addUser), search by email
        if (!profileDoc.exists) {
          debugPrint('AuthService: Profile not found by UID. Fetching by email "$email"...');
          final fallbackDoc = await _userService.getUserByEmail(email);
          if (fallbackDoc != null) {
            profileDoc = fallbackDoc;
          }
        }

        if (profileDoc.exists) {
          final data = profileDoc.data();
          if (data != null) {
            data['id'] = profileDoc.id; // ensure ID is set
            _currentUser = User.fromJson(data);
            
            debugPrint('AuthService: User logged in: ${_currentUser!.username} with role ${_currentUser!.role}');
            await _saveUserData(_currentUser!.toJson());
            return true;
          } else {
            debugPrint('AuthService: WARNING - Profile document data is null');
            throw Exception('User profile data is invalid. Contact administrator.');
          }
        } else {
          debugPrint('AuthService: WARNING - User profile document not found in Firestore');
          throw Exception('User profile not found in database. Contact administrator.');
        }
      }
      return false;
    } catch (e) {
      debugPrint('AuthService: Login error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      await _clearUserData();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<bool> checkAuth() async {
    return await loadUserData();
  }

  /// Sends a password-reset email using Firebase Auth
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.userKey, jsonEncode(userData));
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.userKey);
  }

  Future<bool> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if the Firebase user is logged in
      if (_authService.currentFirebaseUser == null) {
        return false;
      }

      // Check if we have user data
      final userDataString = prefs.getString(AppConfig.userKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Load user data error: $e');
      return false;
    }
  }
}
