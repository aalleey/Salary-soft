class Attendance {
  final String id;
  final String? clientId; // The client this attendance belongs to
  final String staffId;
  final String staffName;
  final int month;
  final int year;
  final int absents;
  final int lates;
  final int halfLeaves;

  // Daily Logging Fields
  final String? date; // 'YYYY-MM-DD'
  final String? checkInTime; // ISO 8601
  final String? checkOutTime; // ISO 8601
  final double totalHours;
  final String? status; // 'present', 'absent', 'leave'

  // Monthly Overrides
  final double totalWorkingHours;
  final double totalLectures;

  Attendance({
    required this.id,
    this.clientId,
    required this.staffId,
    required this.staffName,
    required this.month,
    required this.year,
    required this.absents,
    this.lates = 0,
    this.halfLeaves = 0,
    this.date,
    this.checkInTime,
    this.checkOutTime,
    this.totalHours = 0.0,
    this.status,
    this.totalWorkingHours = 0.0,
    this.totalLectures = 0.0,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'],
      staffId: json['staffId'] ?? json['employeeId'] ?? '',
      staffName: json['staffName'] ?? '',
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      absents: json['absents'] ?? 0,
      lates: json['lates'] ?? 0,
      halfLeaves: json['halfLeaves'] ?? 0,
      date: json['date'],
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0.0,
      status: json['status'],
      totalWorkingHours: (json['totalWorkingHours'] as num?)?.toDouble() ?? 0.0,
      totalLectures: (json['totalLectures'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'staffId': staffId,
      'employeeId': staffId,
      'staffName': staffName,
      'month': month,
      'year': year,
      'absents': absents,
      'lates': lates,
      'halfLeaves': halfLeaves,
      if (date != null) 'date': date,
      if (checkInTime != null) 'checkInTime': checkInTime,
      if (checkOutTime != null) 'checkOutTime': checkOutTime,
      'totalHours': totalHours,
      if (status != null) 'status': status,
      'totalWorkingHours': totalWorkingHours,
      'totalLectures': totalLectures,
    };
  }
}
