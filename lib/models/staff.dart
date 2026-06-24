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
  final String salaryType; // 'Monthly', 'Hourly', or 'Lecture'
  final String? bankAccount;
  final String? emergencyContact;
  final String? notes;
  final String? profileImageUrl;

  // Hourly and Custom Calculation Fields
  final double hourlyRate;
  final String calculationType; // 'absent_based' or 'present_based'

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
    this.hourlyRate = 0.0,
    this.calculationType = 'absent_based',
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'],
      name: json['name'] ?? '',
      salary: (json['basicSalary'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'] ?? '',
      campus: json['campusId'] is Map ? (json['campusId']['_id'] ?? '') : (json['campusId'] ?? ''),
      isActive: json['status'] == 'active' || json['isDeleted'] == false,
      password: json['password'],
      fatherHusbandName: json['fatherName'],
      cnic: json['cnic'],
      address: json['address'],
      designation: json['designation'],
      joiningDate: json['joiningDate'],
      salaryType: json['salaryType'] == 'lecture_based'
          ? 'Lecture'
          : (json['salaryType'] == 'hourly' ? 'Hourly' : 'Monthly'),
      bankAccount: json['bankAccount'],
      emergencyContact: json['emergencyContact'],
      notes: json['notes'],
      profileImageUrl: json['profileImage'],
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      calculationType: json['calculationType'] ?? 'absent_based',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'name': name,
      'basicSalary': salary,
      'phone': phone,
      'campusId': campus.isNotEmpty ? campus : null,
      'status': isActive ? 'active' : 'inactive',
      'password': password,
      'fatherName': fatherHusbandName,
      'cnic': cnic,
      'address': address,
      'designation': (designation == null || designation!.isEmpty) ? 'Staff' : designation,
      'joiningDate': joiningDate,
      'salaryType': salaryType == 'Lecture'
          ? 'lecture_based'
          : (salaryType == 'Hourly' ? 'hourly' : 'monthly'),
      'bankAccount': bankAccount,
      'emergencyContact': emergencyContact,
      'notes': notes,
      'profileImage': profileImageUrl,
      'hourlyRate': hourlyRate,
      'calculationType': calculationType,
    };
  }
}
