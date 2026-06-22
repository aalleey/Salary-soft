
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

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] : (json['userId'] ?? ''),
      userName: json['userId'] is Map ? json['userId']['name'] : (json['userName'] ?? ''),
      clientId: json['clientId'],
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      ip: json['ip'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'clientId': clientId,
      'action': action,
      'details': details,
      'ip': ip,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
