import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../auth/models/app_user.dart';

/// Central authentication state manager.
///
/// Exposes [currentUser], [userRole], [isAuthenticated], [isLoading], [error],
/// plus remember-me helpers and password-reset support.
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _activeCampus;

  static const _kSavedUsername = 'saved_username';
  static const _kRememberMe = 'remember_me';

  // ──────────────────────────────────────────────────────────────────────────
  // Getters
  // ──────────────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  User? get currentUser => _authService.currentUser;
  String? get activeCampus => _activeCampus;

  void setActiveCampus(String? campus) {
    _activeCampus = campus;
    notifyListeners();
  }

  void _initializeActiveCampus() {
    final user = currentUser;
    if (user != null) {
      if (user.assignedCampuses.isNotEmpty) {
        _activeCampus = user.assignedCampuses.first;
      } else {
        _activeCampus = null;
      }
    }
  }

  /// Typed role enum derived from [currentUser.role].
  UserRole? get userRole {
    final user = currentUser;
    if (user == null) return null;
    return roleFromString(user.role);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Auth Actions
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasUser = await _authService.loadUserData();
      if (hasUser) {
        _isAuthenticated = await _authService.checkAuth();
        if (_isAuthenticated) {
          _initializeActiveCampus();
        }
      }
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Performs login. Pass [rememberMe] = true to persist the username.
  Future<bool> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('AuthProvider: login attempt for $username');
      final success = await _authService.login(username, password);
      _isAuthenticated = success;

      if (success) {
        debugPrint(
          'AuthProvider: login OK — role: ${currentUser?.role}',
        );
        _initializeActiveCampus();
        await _handleRememberMe(username, rememberMe);
      } else {
        _error = 'Login failed. Please check your credentials.';
        debugPrint('AuthProvider: login failed for $username');
      }

      return success;
    } catch (e) {
      debugPrint('AuthProvider: login exception — $e');
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
      _activeCampus = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Password Reset
  // ──────────────────────────────────────────────────────────────────────────

  /// Sends a Firebase password-reset email.
  /// Returns null on success, or an error message string on failure.
  Future<String?> sendPasswordReset(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _authService.sendPasswordReset(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Remember Me
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the last saved username if "remember me" was checked.
  Future<String?> getSavedUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_kRememberMe) ?? false;
      if (!remember) return null;
      return prefs.getString(_kSavedUsername);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleRememberMe(String username, bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRememberMe, rememberMe);
      if (rememberMe) {
        await prefs.setString(_kSavedUsername, username);
      } else {
        await prefs.remove(_kSavedUsername);
      }
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Misc
  // ──────────────────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
