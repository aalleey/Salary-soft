import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/audit_log.dart';

class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> log(AuditLog logData) async {
    try {
      await _firestore.collection('audit_logs').add(logData.toFirestore());
    } catch (e) {
      debugPrint('Error saving audit log: $e');
      // We don't rethrow because audit logging shouldn't crash the main operation
    }
  }

  Future<List<AuditLog>> getLogs({String? clientId, int limit = 100}) async {
    try {
      Query query = _firestore.collection('audit_logs').orderBy('created_at', descending: true);
      
      if (clientId != null) {
        query = query.where('client_id', isEqualTo: clientId);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      debugPrint('Error getting audit logs: $e');
      return [];
    }
  }
}
