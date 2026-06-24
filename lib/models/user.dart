import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String? clientId;
  final String? campusId;
  final String username;
  final String email;
  final String role;
  final List<String> permissions;

  User({
    required this.id,
    this.clientId,
    this.campusId,
    required this.username,
    required this.email,
    required this.role,
    this.permissions = const [],
  });

  bool hasPermission(String permissionName) {
    if (role == 'super_admin' || role == 'client_admin') return true;
    return permissions.contains(permissionName);
  }

  List<String> get assignedCampuses {
    if (campusId != null && campusId!.isNotEmpty) {
      return [campusId!];
    }
    return [];
  }

  // Parses user data directly from the Node.js API response
  factory User.fromJson(Map<String, dynamic> json) {
    debugPrint('User.fromJson: json[\'permissions\'] value is "${json['permissions']}" with type: ${json['permissions']?.runtimeType}');
    List<String> perms = [];
    if (json['permissions'] != null) {
      if (json['permissions'] is Map) {
        final Map<dynamic, dynamic> map = json['permissions'];
        map.forEach((key, value) {
          if (value == true) {
            perms.add(key.toString());
          }
        });
      } else if (json['permissions'] is Iterable) {
        perms = List<String>.from(json['permissions']);
      }
    }

    String? resolvedCampusId = json['campusId'] ?? json['campus_id'];
    if (resolvedCampusId == null && json['assigned_campuses'] is List) {
      final List assigned = json['assigned_campuses'];
      if (assigned.isNotEmpty) {
        resolvedCampusId = resolvedCampusId ?? assigned.first.toString();
      }
    }

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'] ?? json['client_id'] ?? (json['instituteName'] != null ? (json['_id'] ?? json['id'] ?? '') : null),
      campusId: resolvedCampusId,
      username: json['username'] ?? json['name'] ?? json['ownerName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? (json['instituteName'] != null ? 'client_admin' : 'staff'),
      permissions: perms,
    );
  }

  // For SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'id': id, 
      'clientId': clientId,
      'campusId': campusId,
      'name': username, 
      'email': email,
      'role': role, 
      'permissions': permissions,
    };
  }
}
