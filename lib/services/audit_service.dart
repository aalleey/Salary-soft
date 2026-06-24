import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log.dart';

class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _withDocId(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    data['_id'] = doc.id;
    return data;
  }

  Future<void> log(AuditLog logData) async {
    try {
      await _firestore.collection('audit').add(logData.toJson());
    } catch (e) {
      debugPrint('Error saving audit log: $e');
      // We don't rethrow because audit logging shouldn't crash the main operation
    }
  }

  Future<List<AuditLog>> getLogs({String? clientId, int limit = 100}) async {
    try {
      Query query = _firestore.collection('audit');
      if (clientId != null) {
        query = query.where('clientId', isEqualTo: clientId);
      }
      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AuditLog.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting audit logs: $e');
      return [];
    }
  }
}
