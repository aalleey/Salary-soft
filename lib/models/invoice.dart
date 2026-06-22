import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String id;
  final String clientId;
  final String? paymentId;
  final String invoiceNumber; // e.g., INV-2026-0001
  final String clientName;
  final String packageName;
  final double amount;
  final DateTime issueDate;
  final DateTime dueDate;
  final String status; // paid, unpaid, overdue
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.clientId,
    this.paymentId,
    required this.invoiceNumber,
    required this.clientName,
    required this.packageName,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  factory Invoice.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Invoice(
      id: documentId,
      clientId: data['client_id'] ?? '',
      paymentId: data['payment_id'],
      invoiceNumber: data['invoice_number'] ?? '',
      clientName: data['client_name'] ?? '',
      packageName: data['package_name'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      issueDate: data['issue_date'] != null 
          ? (data['issue_date'] as Timestamp).toDate() 
          : DateTime.now(),
      dueDate: data['due_date'] != null 
          ? (data['due_date'] as Timestamp).toDate() 
          : DateTime.now().add(const Duration(days: 7)),
      status: data['status'] ?? 'unpaid',
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'client_id': clientId,
      'payment_id': paymentId,
      'invoice_number': invoiceNumber,
      'client_name': clientName,
      'package_name': packageName,
      'amount': amount,
      'issue_date': Timestamp.fromDate(issueDate),
      'due_date': Timestamp.fromDate(dueDate),
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
