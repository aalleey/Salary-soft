
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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      userId: json['userId'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
