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

  factory Attendance.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return Attendance(
      id: documentId,
      clientId: data['client_id'],
      staffId: data['staff_id'] ?? '',
      staffName: data['staff_name'] ?? '',
      month: data['month'] ?? 0,
      year: data['year'] ?? 0,
      absents: data['absents'] ?? 0,
      lates: data['lates'] ?? 0,
      halfLeaves: data['half_leaves'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'client_id': clientId,
      'staff_id': staffId,
      'staff_name': staffName,
      'month': month,
      'year': year,
      'absents': absents,
      'lates': lates,
      'half_leaves': halfLeaves,
    };
  }
}
