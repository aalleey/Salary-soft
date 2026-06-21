class Advance {
  final String id;
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

  factory Advance.fromFirestore(Map<String, dynamic> data, String documentId) {
    // For backward compatibility, if month/year not set, parse from date
    int month;
    int year;

    if (data['advance_month'] != null && data['advance_year'] != null) {
      month = data['advance_month'] as int;
      year = data['advance_year'] as int;
    } else {
      // Fallback: parse from advance_date
      try {
        final date = DateTime.parse(data['advance_date'] ?? '');
        month = date.month;
        year = date.year;
      } catch (e) {
        month = DateTime.now().month;
        year = DateTime.now().year;
      }
    }

    return Advance(
      id: documentId,
      staffId: data['staff_id'] ?? '',
      staffName: data['staff_name'] ?? '',
      advanceAmount: (data['advance_amount'] as num?)?.toDouble() ?? 0.0,
      advanceDate: data['advance_date'] ?? '',
      description: data['description'],
      advanceMonth: month,
      advanceYear: year,
      createdBy: data['created_by'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'staff_id': staffId,
      'staff_name': staffName,
      'advance_amount': advanceAmount,
      'advance_date': advanceDate,
      'description': description,
      'advance_month': advanceMonth,
      'advance_year': advanceYear,
      'created_by': createdBy,
      'notes': notes,
    };
  }
}
