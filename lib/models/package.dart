
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

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      staffLimit: json['staffLimit'] ?? 0,
      campusLimit: json['campusLimit'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'staffLimit': staffLimit,
      'campusLimit': campusLimit,
      'features': features,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
