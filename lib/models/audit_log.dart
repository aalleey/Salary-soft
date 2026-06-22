import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String userId;
  final String userName;
  final String? clientId; // The client this action belongs to
  final String action; // e.g., staff_created, payment_added
  final String details;
  final String? ip;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    this.clientId,
    required this.action,
    required this.details,
    this.ip,
    required this.createdAt,
  });

  factory AuditLog.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AuditLog(
      id: documentId,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      clientId: data['client_id'],
      action: data['action'] ?? '',
      details: data['details'] ?? '',
      ip: data['ip'],
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'user_name': userName,
      'client_id': clientId,
      'action': action,
      'details': details,
      'ip': ip,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
