class Advance {
  final String id;
  final String? clientId; // The client this advance belongs to
  final String staffId;
  final String staffName;
  final double advanceAmount;
  final String advanceDate;
  final String? description;
  final int advanceMonth; // Month to deduct from (1-12)
  final int advanceYear; // Year to deduct from
  final String? createdBy;
  final String? notes;

  Advance({
    required this.id,
    this.clientId,
    required this.staffId,
    required this.staffName,
    required this.advanceAmount,
    required this.advanceDate,
    this.description,
    required this.advanceMonth,
    required this.advanceYear,
    this.createdBy,
    this.notes,
  });

  factory Advance.fromJson(Map<String, dynamic> json) {
    int month = json['month'] ?? DateTime.now().month;
    int year = json['year'] ?? DateTime.now().year;

    return Advance(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'],
      staffId: json['staffId'] ?? '',
      staffName: json['staffId'] is Map ? json['staffId']['name'] : (json['staffName'] ?? ''),
      advanceAmount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      advanceDate: json['createdAt'] ?? '',
      description: json['reason'],
      advanceMonth: month,
      advanceYear: year,
      createdBy: json['createdBy'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'staffId': staffId,
      'staffName': staffName,
      'amount': advanceAmount,
      'createdAt': advanceDate,
      'reason': description,
      'month': advanceMonth,
      'year': advanceYear,
      'createdBy': createdBy,
      'notes': notes,
    };
  }
}
