import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> sendNotification(AppNotification notification) async {
    try {
      final docRef = await _firestore.collection('notifications').add(notification.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  Future<List<AppNotification>> getClientNotifications(String clientId, {String? userId}) async {
    try {
      Query query = _firestore
          .collection('notifications')
          .where('client_id', isEqualTo: clientId);
      
      if (userId != null) {
        query = query.where('user_id', whereIn: [userId, null]);
      }

      final snapshot = await query.orderBy('created_at', descending: true).get();
      return snapshot.docs.map((doc) => AppNotification.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({'is_read': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }
}
