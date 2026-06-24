import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _withDocId(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    data['_id'] = doc.id;
    return data;
  }

  Future<String> sendNotification(AppNotification notification) async {
    try {
      final docRef = await _firestore.collection('notifications').add(notification.toJson());
      return docRef.id;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  Future<List<AppNotification>> getClientNotifications(String clientId, {String? userId}) async {
    try {
      Query query = _firestore.collection('notifications')
          .where('clientId', isEqualTo: clientId);
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AppNotification.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }
}
