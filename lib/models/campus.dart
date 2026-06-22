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

  factory Campus.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Campus(
      id: documentId,
      clientId: data['client_id'],
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
      'client_id': clientId,
      'name': name, 
      'location': location,
      'created_by': createdBy,
      'created_at': createdAt
    };
  }
}
