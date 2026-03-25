import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  User? get currentUser => _authService.currentUser;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try to load user from local storage
      final hasUser = await _authService.loadUserData();
      if (hasUser) {
        // Verify with server
        _isAuthenticated = await _authService.checkAuth();
      }
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Attempting login for: $username');
      final success = await _authService.login(username, password);
      _isAuthenticated = success;

      if (!success) {
        _error = 'Login failed. Please check your credentials.';
        print('AuthProvider: Login failed for user: $username');
      } else {
        print('AuthProvider: Login successful for user: $username');
      }

      return success;
    } catch (e) {
      print('AuthProvider: Exception during login: $e');
      _error = 'Login error: ${e.toString()}';
      _isAuthenticated = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _isAuthenticated = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
