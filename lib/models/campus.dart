class Campus {
  final String id;
  final String name;
  final DateTime createdAt;

  Campus({required this.id, required this.name, required this.createdAt});

  factory Campus.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Campus(
      id: documentId,
      name: data['name'] ?? '',
      createdAt: data['created_at'] != null
          ? (data['created_at'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'created_at': createdAt};
  }
}
