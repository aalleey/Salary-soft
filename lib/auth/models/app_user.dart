import 'package:flutter/material.dart';

/// The hierarchical roles in SalarySoft mapped from the Node.js API.
enum UserRole { superAdmin, clientAdmin, lowerAdmin, staff }

extension UserRoleX on UserRole {
  /// Human-readable display name.
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'App Owner';
      case UserRole.clientAdmin:
        return 'Client Admin';
      case UserRole.lowerAdmin:
        return 'Admin (Sub-admin)';
      case UserRole.staff:
        return 'Staff';
    }
  }

  /// Short label for badges.
  String get shortLabel {
    switch (this) {
      case UserRole.superAdmin:
        return 'SUPER ADMIN';
      case UserRole.clientAdmin:
        return 'ADMIN';
      case UserRole.lowerAdmin:
        return 'ADMIN';
      case UserRole.staff:
        return 'STAFF';
    }
  }

  /// API payload string value.
  String get apiValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.clientAdmin:
        return 'client_admin';
      case UserRole.lowerAdmin:
        return 'lower_admin';
      case UserRole.staff:
        return 'staff';
    }
  }

  /// Brand colour for each role.
  Color get color {
    switch (this) {
      case UserRole.superAdmin:
        return const Color(0xFFF806CC); // Magenta
      case UserRole.clientAdmin:
        return const Color(0xFF7C3AED); // Purple
      case UserRole.lowerAdmin:
        return const Color(0xFF7C3AED); // Purple
      case UserRole.staff:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  /// Secondary/darker colour for gradients.
  Color get colorDark {
    switch (this) {
      case UserRole.superAdmin:
        return const Color(0xFF7C3AED);
      case UserRole.clientAdmin:
        return const Color(0xFF4C1D95);
      case UserRole.lowerAdmin:
        return const Color(0xFF4C1D95);
      case UserRole.staff:
        return const Color(0xFF1D4ED8);
    }
  }

  List<Color> get gradient => [colorDark, color];

  /// Icon representing the role.
  IconData get icon {
    switch (this) {
      case UserRole.superAdmin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.clientAdmin:
        return Icons.manage_accounts_rounded;
      case UserRole.lowerAdmin:
        return Icons.manage_accounts_rounded;
      case UserRole.staff:
        return Icons.badge_rounded;
    }
  }

  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isClientAdmin => this == UserRole.clientAdmin;
  bool get isLowerAdmin => this == UserRole.lowerAdmin;
  bool get isStaff => this == UserRole.staff;
}

/// Parses a raw API role string into [UserRole].
UserRole roleFromString(String? raw) {
  final normalized = (raw ?? '').toLowerCase().trim();
  switch (normalized) {
    case 'super_admin':
      return UserRole.superAdmin;
    case 'client_admin':
    case 'admin':
      return UserRole.clientAdmin;
    case 'lower_admin':
      return UserRole.lowerAdmin;
    case 'staff':
      return UserRole.staff;
    default:
      return UserRole.staff; // Default to least privileged
  }
}
