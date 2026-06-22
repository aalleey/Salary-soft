import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final String id;
  final String clientId;
  final String packageId;
  final String packageName;
  final DateTime startDate;
  final DateTime endDate;
  final int graceDays;
  final String status; // active, expired, pending, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.clientId,
    required this.packageId,
    required this.packageName,
    required this.startDate,
    required this.endDate,
    this.graceDays = 7,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  bool get isInGracePeriod {
    if (!isExpired) return false;
    final graceEndDate = endDate.add(Duration(days: graceDays));
    return DateTime.now().isBefore(graceEndDate);
  }
  
  bool get isFullyLocked {
    return isExpired && !isInGracePeriod;
  }

  int get daysUntilExpiry {
    if (isExpired) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  factory Subscription.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Subscription(
      id: documentId,
      clientId: data['client_id'] ?? '',
      packageId: data['package_id'] ?? '',
      packageName: data['package_name'] ?? '',
      startDate: data['start_date'] != null 
          ? (data['start_date'] as Timestamp).toDate() 
          : DateTime.now(),
      endDate: data['end_date'] != null 
          ? (data['end_date'] as Timestamp).toDate() 
          : DateTime.now().add(const Duration(days: 30)),
      graceDays: data['grace_days'] ?? 7,
      status: data['status'] ?? 'pending',
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updated_at'] != null 
          ? (data['updated_at'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'client_id': clientId,
      'package_id': packageId,
      'package_name': packageName,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'grace_days': graceDays,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
