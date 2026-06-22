import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'firebase_auth_service.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<bool> login(String username, String password) async {
    try {
      debugPrint('AuthService: Calling FirebaseAuthService.login()');
      bool success = await _firebaseAuth.login(username, password);
      debugPrint('AuthService: FirebaseAuthService.login() returned: $success');

      if (success) {
        _currentUser = _firebaseAuth.currentUser;
        FirebaseService().setAppUser(_currentUser);
      } else {
        // Try staff login if admin login fails
        debugPrint('AuthService: Admin login failed, trying staff login...');
        final staff = await FirebaseService().verifyStaffCredentials(
          username,
          password,
        );

        if (staff != null) {
          debugPrint('AuthService: Staff login successful: ${staff.name}');
          _currentUser = User(
            id: staff.id,
            clientId: staff.clientId,
            username: staff.name,
            role: 'employee',
            assignedCampuses: [staff.campus],
          );
          FirebaseService().setAppUser(_currentUser);
          success = true;
        }
      }

      if (success) {
        if (_currentUser != null) {
          debugPrint('AuthService: User logged in: ${_currentUser!.username}');
          await _saveUserData(_currentUser!.toJson());
        } else {
          debugPrint(
            'AuthService: WARNING - Login successful but currentUser is null',
          );
        }
      } else {
        debugPrint('AuthService: Login failed');
      }
      return success;
    } catch (e) {
      debugPrint('AuthService: Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.logout();
      _currentUser = null;
      FirebaseService().setAppUser(null);
      await _clearUserData();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<bool> checkAuth() async {
    try {
      final success = await _firebaseAuth.checkAuth();
      if (success) {
        _currentUser = _firebaseAuth.currentUser;
        FirebaseService().setAppUser(_currentUser);
      }
      return success;
    } catch (e) {
      debugPrint('Auth check error: $e');
      return false;
    }
  }

  /// Sends a Firebase password-reset email.
  /// Returns null on success, or an error message string on failure.
  Future<String?> sendPasswordReset(String email) async {
    return _firebaseAuth.sendPasswordResetEmail(email);
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
      final success = await _firebaseAuth.loadUserData();
      if (success) {
        _currentUser = _firebaseAuth.currentUser;
        if (_currentUser != null) {
          FirebaseService().setAppUser(_currentUser);
          await _saveUserData(_currentUser!.toJson());
        }
        return true;
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(AppConfig.userKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        FirebaseService().setAppUser(_currentUser);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Load user data error: $e');
      return false;
    }
  }
}
