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
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'],
      staffId: json['staffId'] ?? '',
      staffName: json['staffName'] ?? '',
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      absents: json['absents'] ?? 0,
      lates: json['lates'] ?? 0,
      halfLeaves: json['halfLeaves'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'staffId': staffId,
      'staffName': staffName,
      'month': month,
      'year': year,
      'absents': absents,
      'lates': lates,
      'halfLeaves': halfLeaves,
    };
  }
}
