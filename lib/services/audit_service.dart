import 'api_service.dart';
import 'package:flutter/foundation.dart';
import '../models/audit_log.dart';

class AuditService {
  static final AuditService _instance = AuditService._internal();
  factory AuditService() => _instance;
  AuditService._internal();

  final ApiService _api = ApiService();

  Future<void> log(AuditLog logData) async {
    try {
      await _api.post('audit', body: logData.toJson());
    } catch (e) {
      debugPrint('Error saving audit log: $e');
      // We don't rethrow because audit logging shouldn't crash the main operation
    }
  }

  Future<List<AuditLog>> getLogs({String? clientId, int limit = 100}) async {
    try {
      final queryParams = <String, String>{};
      if (clientId != null) queryParams['clientId'] = clientId;
      queryParams['limit'] = limit.toString();

      final response = await _api.get('audit', queryParams: queryParams);
      final List<dynamic> data = response;
      return data.map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting audit logs: $e');
      return [];
    }
  }
}
