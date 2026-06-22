import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    try {
      debugPrint('AuthService: Calling API for login...');
      
      final response = await _apiService.post(
        'auth/login',
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false, // Don't send token for login
      );

      debugPrint('AuthService: Login successful');
      
      // Save the access token securely
      final String token = response['accessToken'];
      await _apiService.saveToken(token);

      // Parse and save the user data
      _currentUser = User.fromJson(response);
      
      if (_currentUser != null) {
        debugPrint('AuthService: User logged in: ${_currentUser!.username} with role ${_currentUser!.role}');
        await _saveUserData(_currentUser!.toJson());
        return true;
      } else {
        debugPrint('AuthService: WARNING - Login successful but failed to parse user');
        return false;
      }
    } catch (e) {
      debugPrint('AuthService: Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.clearToken();
      _currentUser = null;
      await _clearUserData();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  Future<bool> checkAuth() async {
    return await loadUserData();
  }

  /// Sends a password-reset email using the API
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _apiService.post(
        'auth/forgot-password',
        body: {'email': email},
        requiresAuth: false,
      );
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
      
      // Check if we have a token
      final token = prefs.getString(AppConfig.tokenKey);
      if (token == null || token.isEmpty) {
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
