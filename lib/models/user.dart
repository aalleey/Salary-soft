class User {
  final String id;
  final String? clientId; // The client this user belongs to
  final String username;
  final String role;
  final List<String> assignedCampuses;
  final Map<String, bool> permissions;

  User({
    required this.id,
    this.clientId,
    required this.username,
    required this.role,
    required this.assignedCampuses,
    this.permissions = const {},
  });

  bool hasPermission(String permissionName) {
    if (role == 'super_admin') return true;
    return permissions[permissionName] ?? false;
  }

  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    List<String> campuses = [];
    if (data['assigned_campuses'] != null) {
      campuses = List<String>.from(data['assigned_campuses']);
    } else if (data['campus'] != null && data['campus'] is String) {
      final String legacyCampus = data['campus'];
      if (legacyCampus.isNotEmpty) {
        campuses = [legacyCampus];
      }
    }

    Map<String, bool> perms = {};
    if (data['permissions'] != null) {
      perms = Map<String, bool>.from(data['permissions']);
    }

    return User(
      id: documentId,
      clientId: data['client_id'],
      username: data['username'] ?? '',
      role: data['role'] ?? 'admin',
      assignedCampuses: campuses,
      permissions: perms,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'client_id': clientId,
      'username': username, 
      'role': role, 
      'assigned_campuses': assignedCampuses,
      'permissions': permissions,
    };
  }

  // For SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'id': id, 
      'clientId': clientId,
      'username': username, 
      'role': role, 
      'assignedCampuses': assignedCampuses,
      'permissions': permissions,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    List<String> campuses = [];
    if (json['assignedCampuses'] != null) {
      campuses = List<String>.from(json['assignedCampuses']);
    } else if (json['campus'] != null && json['campus'] is String) {
      final String legacyCampus = json['campus'];
      if (legacyCampus.isNotEmpty) {
        campuses = [legacyCampus];
      }
    }

    Map<String, bool> perms = {};
    if (json['permissions'] != null) {
      perms = Map<String, bool>.from(json['permissions']);
    }

    return User(
      id: json['id'] ?? '',
      clientId: json['clientId'],
      username: json['username'] ?? '',
      role: json['role'] ?? 'admin',
      assignedCampuses: campuses,
      permissions: perms,
    );
  }
}
