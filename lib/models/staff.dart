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

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'],
      name: json['name'] ?? '',
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'] ?? '',
      campus: json['campus'] ?? '',
      isActive: json['isActive'] ?? true,
      password: json['password'],
      fatherHusbandName: json['fatherHusbandName'],
      cnic: json['cnic'],
      address: json['address'],
      designation: json['designation'],
      joiningDate: json['joiningDate'],
      salaryType: json['salaryType'] ?? 'Monthly',
      bankAccount: json['bankAccount'],
      emergencyContact: json['emergencyContact'],
      notes: json['notes'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
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
