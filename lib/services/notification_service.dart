import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _api = ApiService();

  Future<String> sendNotification(AppNotification notification) async {
    try {
      final response = await _api.post('notifications', body: notification.toJson());
      return response['_id'] ?? response['id'];
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  Future<List<AppNotification>> getClientNotifications(String clientId, {String? userId}) async {
    try {
      final queryParams = <String, String>{'clientId': clientId};
      if (userId != null) queryParams['userId'] = userId;

      final response = await _api.get('notifications', queryParams: queryParams);
      final List<dynamic> data = response;
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.put('notifications/$notificationId/read');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }
}
