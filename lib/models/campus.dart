class Campus {
  final String id;
  final String? clientId; // The client this campus belongs to
  final String name;
  final String? location;
  final String? createdBy;
  final DateTime createdAt;

  Campus({
    required this.id, 
    this.clientId,
    required this.name, 
    this.location,
    this.createdBy,
    required this.createdAt
  });

  factory Campus.fromJson(Map<String, dynamic> json) {
    return Campus(
      id: json['_id'] ?? json['id'] ?? '',
      clientId: json['clientId'],
      name: json['name'] ?? '',
      location: json['address'],
      createdBy: json['createdBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'name': name, 
      'address': location,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String()
    };
  }
}
