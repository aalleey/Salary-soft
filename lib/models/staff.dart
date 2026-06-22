class Staff {
  final String id;
  final String? clientId; // The client this staff belongs to
  final String name;
  final double salary;
  final String phone;
  final String campus;
  final bool isActive;
  final String? password;
  
  // Expanded Fields
  final String? fatherHusbandName;
  final String? cnic;
  final String? address;
  final String? designation;
  final String? joiningDate;
  final String salaryType; // 'Monthly' or 'Lecture'
  final String? bankAccount;
  final String? emergencyContact;
  final String? notes;
  final String? profileImageUrl;

  Staff({
    required this.id,
    this.clientId,
    required this.name,
    required this.salary,
    required this.phone,
    required this.campus,
    this.isActive = true,
    this.password,
    this.fatherHusbandName,
    this.cnic,
    this.address,
    this.designation,
    this.joiningDate,
    this.salaryType = 'Monthly',
    this.bankAccount,
    this.emergencyContact,
    this.notes,
    this.profileImageUrl,
  });

  factory Staff.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Staff(
      id: documentId,
      clientId: data['client_id'],
      name: data['name'] ?? '',
      salary: (data['salary'] as num?)?.toDouble() ?? 0.0,
      phone: data['phone'] ?? '',
      campus: data['campus'] ?? '',
      isActive: data['isActive'] ?? true,
      password: data['password'],
      fatherHusbandName: data['fatherHusbandName'],
      cnic: data['cnic'],
      address: data['address'],
      designation: data['designation'],
      joiningDate: data['joiningDate'],
      salaryType: data['salaryType'] ?? 'Monthly',
      bankAccount: data['bankAccount'],
      emergencyContact: data['emergencyContact'],
      notes: data['notes'],
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'client_id': clientId,
      'name': name,
      'salary': salary,
      'phone': phone,
      'campus': campus,
      'isActive': isActive,
      'password': password,
      'fatherHusbandName': fatherHusbandName,
      'cnic': cnic,
      'address': address,
      'designation': designation,
      'joiningDate': joiningDate,
      'salaryType': salaryType,
      'bankAccount': bankAccount,
      'emergencyContact': emergencyContact,
      'notes': notes,
      'profileImageUrl': profileImageUrl,
    };
  }
}
