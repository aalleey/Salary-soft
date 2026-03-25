class User {
  final String id;
  final String username;
  final String role;
  final String? campus;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.campus,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Handle campus field - treat empty string as null
    String? campusValue;
    if (data['campus'] != null && data['campus'] is String) {
      final campus = data['campus'] as String;
      campusValue = campus.isNotEmpty ? campus : null;
    }

    return User(
      id: documentId,
      username: data['username'] ?? '',
      role: data['role'] ?? 'admin',
      campus: campusValue,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'username': username, 'role': role, 'campus': campus};
  }

  // For SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'role': role, 'campus': campus};
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle campus - treat empty string as null
    String? campusValue;
    if (json['campus'] != null && json['campus'] is String) {
      final campus = json['campus'] as String;
      campusValue = campus.isNotEmpty ? campus : null;
    }

    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'admin',
      campus: campusValue,
    );
  }
}
