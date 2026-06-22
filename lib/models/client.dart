class Client {
  final String id;
  final String instituteName;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String status; // active, suspended, expired
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final String createdBy;
  final String currency; // 'PKR', 'USD', etc.
  final int clientNumber;

  Client({
    required this.id,
    required this.instituteName,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    this.status = 'active',
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.createdBy,
    this.currency = 'PKR',
    this.clientNumber = 0,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['_id'] ?? json['id'] ?? '',
      instituteName: json['instituteName'] ?? json['name'] ?? '',
      ownerName: json['ownerName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? 'active',
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null 
          ? DateTime.parse(json['deletedAt']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      currency: json['currency'] ?? 'PKR',
      clientNumber: json['clientNumber'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instituteName': instituteName,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'address': address,
      'status': status,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'currency': currency,
      'clientNumber': clientNumber,
    };
  }
}
