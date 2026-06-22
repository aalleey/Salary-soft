import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String clientId;
  final String subscriptionId;
  final double amount;
  final String paymentMethod; // Cash, Bank Transfer, JazzCash, EasyPaisa, Online
  final String? transactionId;
  final DateTime paymentDate;
  final int month;
  final int year;
  final String status; // completed, pending, failed
  final String? notes;
  final String recordedBy;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.clientId,
    required this.subscriptionId,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
    required this.paymentDate,
    required this.month,
    required this.year,
    required this.status,
    this.notes,
    required this.recordedBy,
    required this.createdAt,
  });

  factory Payment.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Payment(
      id: documentId,
      clientId: data['client_id'] ?? '',
      subscriptionId: data['subscription_id'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['payment_method'] ?? 'Cash',
      transactionId: data['transaction_id'],
      paymentDate: data['payment_date'] != null 
          ? (data['payment_date'] as Timestamp).toDate() 
          : DateTime.now(),
      month: data['month'] ?? DateTime.now().month,
      year: data['year'] ?? DateTime.now().year,
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      recordedBy: data['recorded_by'] ?? '',
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'client_id': clientId,
      'subscription_id': subscriptionId,
      'amount': amount,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'payment_date': Timestamp.fromDate(paymentDate),
      'month': month,
      'year': year,
      'status': status,
      'notes': notes,
      'recorded_by': recordedBy,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
