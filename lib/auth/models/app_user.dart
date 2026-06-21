import 'package:flutter/material.dart';

/// The hierarchical roles in SalarySoft.
enum UserRole { superUser, admin, employee }

extension UserRoleX on UserRole {
  /// Human-readable display name.
  String get displayName {
    switch (this) {
      case UserRole.superUser:
        return 'Super User';
      case UserRole.admin:
        return 'Admin';
      case UserRole.employee:
        return 'Employee';
    }
  }

  /// Short label for badges.
  String get shortLabel {
    switch (this) {
      case UserRole.superUser:
        return 'SUPER USER';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.employee:
        return 'STAFF';
    }
  }

  /// Firestore field value.
  String get firestoreValue {
    switch (this) {
      case UserRole.superUser:
        return 'superUser';
      case UserRole.admin:
        return 'admin';
      case UserRole.employee:
        return 'employee';
    }
  }

  /// Brand colour for each role.
  Color get color {
    switch (this) {
      case UserRole.superUser:
        return const Color(0xFFF806CC); // Magenta
      case UserRole.admin:
        return const Color(0xFF7C3AED); // Purple
      case UserRole.employee:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  /// Secondary/darker colour for gradients.
  Color get colorDark {
    switch (this) {
      case UserRole.superUser:
        return const Color(0xFF7C3AED);
      case UserRole.admin:
        return const Color(0xFF4C1D95);
      case UserRole.employee:
        return const Color(0xFF1D4ED8);
    }
  }

  List<Color> get gradient => [colorDark, color];

  /// Icon representing the role.
  IconData get icon {
    switch (this) {
      case UserRole.superUser:
        return Icons.admin_panel_settings_rounded;
      case UserRole.admin:
        return Icons.manage_accounts_rounded;
      case UserRole.employee:
        return Icons.badge_rounded;
    }
  }

  bool get isSuperUser => this == UserRole.superUser;
  bool get isAdmin => this == UserRole.admin;

  /// Whether this role can access owner-only settings.
  bool get canAccessOwnerSettings => this == UserRole.superUser;

  /// Whether this role can manage admins.
  bool get canManageAdmins => this == UserRole.superUser;
}

/// Parses a raw Firestore/SharedPreferences role string into [UserRole].
UserRole roleFromString(String? raw) {
  final normalized = (raw ?? '').toLowerCase().trim().replaceAll(' ', '_');
  switch (normalized) {
    case 'superuser':
    case 'super_user':
    case 'app_owner':
    case 'owner':
      return UserRole.superUser;
    case 'admin':
    case 'campus_admin':
      return UserRole.admin;
    case 'employee':
    case 'staff':
      return UserRole.employee;
    default:
      return UserRole.admin;
  }
}
