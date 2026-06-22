import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import 'api_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiService _api = ApiService();

  Future<String> recordPayment(Payment payment) async {
    try {
      final response = await _api.post('payments', body: payment.toJson());
      return response['_id'] ?? response['id'];
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    }
  }

  Future<List<Payment>> getClientPayments(String clientId) async {
    try {
      final response = await _api.get('payments', queryParams: {'clientId': clientId});
      final List<dynamic> data = response;
      return data.map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting client payments: $e');
      return [];
    }
  }

  Future<List<Payment>> getAllPayments() async {
    try {
      final response = await _api.get('payments');
      final List<dynamic> data = response;
      return data.map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all payments: $e');
      return [];
    }
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    try {
      await _api.put('payments/$paymentId', body: {'status': status});
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      rethrow;
    }
  }
}
