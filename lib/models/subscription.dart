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

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      packageId: json['packageId'] is Map ? json['packageId']['_id'] : (json['packageId'] ?? ''),
      packageName: json['packageId'] is Map ? json['packageId']['name'] : (json['packageName'] ?? ''),
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : DateTime.now().add(const Duration(days: 30)),
      graceDays: json['graceDays'] ?? 7,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'packageId': packageId,
      'packageName': packageName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'graceDays': graceDays,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
