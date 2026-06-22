import 'package:cloud_firestore/cloud_firestore.dart';

class Package {
  final String id;
  final String name; // e.g., Basic, Premium
  final double price; // Monthly price
  final int staffLimit; // 0 for unlimited
  final int campusLimit; // 0 for unlimited
  final List<String> features;
  final bool isActive;
  final DateTime createdAt;

  Package({
    required this.id,
    required this.name,
    required this.price,
    this.staffLimit = 0,
    this.campusLimit = 0,
    this.features = const [],
    this.isActive = true,
    required this.createdAt,
  });

  factory Package.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Package(
      id: documentId,
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      staffLimit: data['staff_limit'] ?? 0,
      campusLimit: data['campus_limit'] ?? 0,
      features: List<String>.from(data['features'] ?? []),
      isActive: data['is_active'] ?? true,
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'staff_limit': staffLimit,
      'campus_limit': campusLimit,
      'features': features,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
