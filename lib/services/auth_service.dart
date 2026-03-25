import 'dart:convert';
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
      print('AuthService: Calling FirebaseAuthService.login()');
      bool success = await _firebaseAuth.login(username, password);
      print('AuthService: FirebaseAuthService.login() returned: $success');

      if (success) {
        _currentUser = _firebaseAuth.currentUser;
      } else {
        // Try staff login if admin login fails
        print('AuthService: Admin login failed, trying staff login...');
        final staff = await FirebaseService().verifyStaffCredentials(
          username,
          password,
        );

        if (staff != null) {
          print('AuthService: Staff login successful: ${staff.name}');
          _currentUser = User(
            id: staff.id,
            username: staff.name,
            role: 'employee',
            campus: staff.campus,
          );
          success = true;
        }
      }

      if (success) {
        if (_currentUser != null) {
          print('AuthService: User logged in: ${_currentUser!.username}');
          await _saveUserData(_currentUser!.toJson());
        } else {
          print(
            'AuthService: WARNING - Login successful but currentUser is null',
          );
        }
      } else {
        print('AuthService: Login failed');
      }
      return success;
    } catch (e) {
      print('AuthService: Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.logout();
      _currentUser = null;
      await _clearUserData();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<bool> checkAuth() async {
    try {
      final success = await _firebaseAuth.checkAuth();
      if (success) {
        _currentUser = _firebaseAuth.currentUser;
      }
      return success;
    } catch (e) {
      print('Auth check error: $e');
      return false;
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.userKey, jsonEncode(userData));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.userKey);
  }

  Future<bool> loadUserData() async {
    try {
      // Try to load from Firebase first
      final success = await _firebaseAuth.loadUserData();
      if (success) {
        _currentUser = _firebaseAuth.currentUser;
        if (_currentUser != null) {
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
        return true;
      }

      return false;
    } catch (e) {
      print('Load user data error: $e');
      return false;
    }
  }
}
