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

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      subscriptionId: json['subscriptionId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['method'] ?? 'Cash',
      transactionId: json['transactionId'],
      paymentDate: json['paymentDate'] != null 
          ? DateTime.parse(json['paymentDate']) 
          : DateTime.now(),
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      recordedBy: json['recordedBy'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'method': paymentMethod,
      'transactionId': transactionId,
      'paymentDate': paymentDate.toIso8601String(),
      'month': month,
      'year': year,
      'status': status,
      'notes': notes,
      'recordedBy': recordedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
