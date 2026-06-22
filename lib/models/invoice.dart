
class Invoice {
  final String id;
  final String clientId;
  final String? paymentId;
  final String invoiceNumber; // e.g., INV-2026-0001
  final String clientName;
  final String packageName;
  final double amount;
  final DateTime issueDate;
  final DateTime dueDate;
  final String status; // paid, unpaid, overdue
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.clientId,
    this.paymentId,
    required this.invoiceNumber,
    required this.clientName,
    required this.packageName,
    required this.amount,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      paymentId: json['paymentId'],
      invoiceNumber: json['invoiceNumber'] ?? '',
      clientName: json['clientName'] ?? '',
      packageName: json['packageName'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      issueDate: json['issueDate'] != null 
          ? DateTime.parse(json['issueDate']) 
          : DateTime.now(),
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate']) 
          : DateTime.now().add(const Duration(days: 7)),
      status: json['status'] ?? 'unpaid',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'paymentId': paymentId,
      'invoiceNumber': invoiceNumber,
      'clientName': clientName,
      'packageName': packageName,
      'amount': amount,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
