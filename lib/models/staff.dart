class Staff {
  final String id;
  final String name;
  final double salary;
  final String phone;
  final String campus;
  final bool isActive;
  final String? password;

  Staff({
    required this.id,
    required this.name,
    required this.salary,
    required this.phone,
    required this.campus,
    this.isActive = true,
    this.password,
  });

  factory Staff.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Staff(
      id: documentId,
      name: data['name'] ?? '',
      salary: (data['salary'] as num?)?.toDouble() ?? 0.0,
      phone: data['phone'] ?? '',
      campus: data['campus'] ?? '',
      isActive: data['isActive'] ?? true,
      password: data['password'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'salary': salary,
      'phone': phone,
      'campus': campus,
      'isActive': isActive,
      'password': password,
    };
  }
}
