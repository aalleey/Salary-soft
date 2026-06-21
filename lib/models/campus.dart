class Campus {
  final String id;
  final String name;
  final String? location;
  final String? createdBy;
  final DateTime createdAt;

  Campus({
    required this.id, 
    required this.name, 
    this.location,
    this.createdBy,
    required this.createdAt
  });

  factory Campus.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Campus(
      id: documentId,
      name: data['name'] ?? '',
      location: data['location'],
      createdBy: data['created_by'],
      createdAt: data['created_at'] != null
          ? (data['created_at'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name, 
      'location': location,
      'created_by': createdBy,
      'created_at': createdAt
    };
  }
}
