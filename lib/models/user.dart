class User {
  final String id;
  final String username;
  final String role;
  final List<String> assignedCampuses;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.assignedCampuses,
  });

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

    return User(
      id: documentId,
      username: data['username'] ?? '',
      role: data['role'] ?? 'admin',
      assignedCampuses: campuses,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username, 
      'role': role, 
      'assigned_campuses': assignedCampuses
    };
  }

  // For SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'id': id, 
      'username': username, 
      'role': role, 
      'assignedCampuses': assignedCampuses
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

    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'admin',
      assignedCampuses: campuses,
    );
  }
}
