import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String clientId;
  final String? userId; // Target user, null if for all admins of client
  final String title;
  final String message;
  final String type; // expiry_warning, payment_reminder, system
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.clientId,
    this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(Map<String, dynamic> data, String documentId) {
    return AppNotification(
      id: documentId,
      clientId: data['client_id'] ?? '',
      userId: data['user_id'],
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'system',
      isRead: data['is_read'] ?? false,
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'client_id': clientId,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
