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
    List<String> perms = [];
    if (json['permissions'] != null) {
      perms = List<String>.from(json['permissions']);
    }

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'],
      campusId: json['campusId'],
      username: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'staff',
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
