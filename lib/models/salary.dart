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

  factory Salary.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Salary(
      id: documentId,
      clientId: data['client_id'],
      staffId: data['staff_id'] ?? '',
      staffName: data['staff_name'] ?? '',
      month: data['month'] ?? 0,
      year: data['year'] ?? 0,
      basicSalary: (data['basic_salary'] as num?)?.toDouble() ?? 0.0,
      deduction: (data['deduction'] as num?)?.toDouble() ?? 0.0,
      totalSalary: (data['total_salary'] as num?)?.toDouble() ?? 0.0,
      absents: (data['absents'] as num?)?.toDouble() ?? 0.0,
      lates: data['lates'] ?? 0,
      advanceAmount: (data['advance_amount'] as num?)?.toDouble() ?? 0.0,
      campus: data['campus'],
      phone: data['phone'],
      isPaid: data['is_paid'] ?? false,
      paidDate: data['paid_date'],
      paidAmount: _parsePaidAmount(data),
      remainingAmount: _parseRemainingAmount(data),
      status: _parseStatus(data),
      notes: data['notes'],
    );
  }

  static double _parsePaidAmount(Map<String, dynamic> data) {
    if (data['paid_amount'] != null) {
      return (data['paid_amount'] as num).toDouble();
    }
    // Legacy fallback
    if (data['is_paid'] == true) {
      return (data['total_salary'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  static double _parseRemainingAmount(Map<String, dynamic> data) {
    if (data['remaining_amount'] != null) {
      return (data['remaining_amount'] as num).toDouble();
    }
    // Legacy fallback
    if (data['is_paid'] == true) return 0.0;
    return (data['total_salary'] as num?)?.toDouble() ?? 0.0;
  }

  static String _parseStatus(Map<String, dynamic> data) {
    if (data['status'] != null) return data['status'] as String;
    // Legacy fallback
    return (data['is_paid'] == true) ? 'Paid' : 'Pending';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'client_id': clientId,
      'staff_id': staffId,
      'staff_name': staffName,
      'month': month,
      'year': year,
      'basic_salary': basicSalary,
      'deduction': deduction,
      'total_salary': totalSalary,
      'absents': absents,
      'lates': lates,
      'advance_amount': advanceAmount,
      'campus': campus,
      'phone': phone,
      'is_paid': isPaid,
      'paid_date': paidDate,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'status': status,
      'notes': notes,
    };
  }
}
