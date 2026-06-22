import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory Client.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Client(
      id: documentId,
      instituteName: data['institute_name'] ?? '',
      ownerName: data['owner_name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      address: data['address'] ?? '',
      status: data['status'] ?? 'active',
      isDeleted: data['is_deleted'] ?? false,
      deletedAt: data['deleted_at'] != null 
          ? (data['deleted_at'] as Timestamp).toDate() 
          : null,
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
      createdBy: data['created_by'] ?? '',
      currency: data['currency'] ?? 'PKR',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'institute_name': instituteName,
      'owner_name': ownerName,
      'phone': phone,
      'email': email,
      'address': address,
      'status': status,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'created_at': Timestamp.fromDate(createdAt),
      'created_by': createdBy,
      'currency': currency,
    };
  }
}
