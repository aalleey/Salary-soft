import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Salary {
  final String id;
  final String? clientId; // The client this salary belongs to
  final String staffId;
  final String staffName;
  final int month;
  final int year;
  final double basicSalary;
  final double deduction;
  final double totalSalary;
  final double absents;
  final int lates;
  final double advanceAmount;
  final String? campus;
  final String? phone;
  final bool isPaid; // Legacy fallback
  final String? paidDate;
  final double paidAmount;
  final double remainingAmount;
  final String status; // 'Paid', 'Partial Paid', 'Pending'
  final String? notes;

  // Helper getters for formatting

  /// Formatted total salary with currency (e.g., "Rs 35,000")
  String get formattedTotalSalary =>
      'Rs ${NumberFormat('#,##0').format(totalSalary)}';

  /// Formatted basic salary with currency
  String get formattedBasicSalary =>
      'Rs ${NumberFormat('#,##0').format(basicSalary)}';

  /// Formatted deduction with currency
  String get formattedDeduction =>
      'Rs ${NumberFormat('#,##0').format(deduction)}';

  /// Formatted advance amount with currency
  String get formattedAdvanceAmount =>
      'Rs ${NumberFormat('#,##0').format(advanceAmount)}';

  /// Status text ("Paid", "Partial Paid", "Pending")
  String get statusText {
    if (status.isNotEmpty && status != 'Pending') return status;
    return isPaid ? 'Paid' : 'Pending';
  }

  /// Status color (green for paid, blue for partial, orange for pending)
  Color get statusColor {
    final s = statusText;
    if (s == 'Paid') return Colors.green;
    if (s == 'Partial Paid') return Colors.blue;
    return Colors.orange;
  }

  /// Month and year formatted (e.g., "January 2026")
  String get monthYearText =>
      DateFormat('MMMM yyyy').format(DateTime(year, month));

  /// Short month and year (e.g., "Jan 2026")
  String get shortMonthYearText =>
      DateFormat('MMM yyyy').format(DateTime(year, month));

  /// Formatted paid date (e.g., "Feb 4, 2026") or null
  String? get formattedPaidDate => paidDate != null
      ? DateFormat('MMM d, yyyy').format(DateTime.parse(paidDate!))
      : null;

  /// Net payable after all deductions (same as totalSalary for now)
  double get netPayable => totalSalary;

  /// Total deductions including absents and advances
  double get totalDeductions => deduction;

  Salary({
    required this.id,
    this.clientId,
    required this.staffId,
    required this.staffName,
    required this.month,
    required this.year,
    required this.basicSalary,
    required this.deduction,
    required this.totalSalary,
    required this.absents,
    this.lates = 0,
    this.advanceAmount = 0.0,
    this.campus,
    this.phone,
    this.isPaid = false,
    this.paidDate,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.status = 'Pending',
    this.notes,
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'],
      staffId: json['staffId'] ?? '',
      staffName: json['staffId'] is Map ? json['staffId']['name'] : (json['staffName'] ?? ''),
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0.0,
      deduction: (json['deduction'] as num?)?.toDouble() ?? 0.0,
      totalSalary: (json['totalSalary'] as num?)?.toDouble() ?? 0.0,
      absents: (json['absents'] as num?)?.toDouble() ?? 0.0,
      lates: json['lates'] ?? 0,
      advanceAmount: (json['advanceAmount'] as num?)?.toDouble() ?? 0.0,
      campus: json['campus'],
      phone: json['phone'],
      isPaid: json['isPaid'] ?? false,
      paidDate: json['paidDate'],
      paidAmount: _parsePaidAmount(json),
      remainingAmount: _parseRemainingAmount(json),
      status: _parseStatus(json),
      notes: json['notes'],
    );
  }

  static double _parsePaidAmount(Map<String, dynamic> json) {
    if (json['paidAmount'] != null) {
      return (json['paidAmount'] as num).toDouble();
    }
    if (json['isPaid'] == true) {
      return (json['totalSalary'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  static double _parseRemainingAmount(Map<String, dynamic> json) {
    if (json['remainingAmount'] != null) {
      return (json['remainingAmount'] as num).toDouble();
    }
    if (json['isPaid'] == true) return 0.0;
    return (json['totalSalary'] as num?)?.toDouble() ?? 0.0;
  }

  static String _parseStatus(Map<String, dynamic> json) {
    if (json['status'] != null) return json['status'] as String;
    return (json['isPaid'] == true) ? 'Paid' : 'Pending';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'staffId': staffId,
      'staffName': staffName,
      'month': month,
      'year': year,
      'basicSalary': basicSalary,
      'deduction': deduction,
      'totalSalary': totalSalary,
      'absents': absents,
      'lates': lates,
      'advanceAmount': advanceAmount,
      'campus': campus,
      'phone': phone,
      'isPaid': isPaid,
      'paidDate': paidDate,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'status': status,
      'notes': notes,
    };
  }
}
