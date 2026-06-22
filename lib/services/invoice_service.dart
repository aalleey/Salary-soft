import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import 'api_service.dart';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  factory InvoiceService() => _instance;
  InvoiceService._internal();

  final ApiService _api = ApiService();

  Future<String> createInvoice(Invoice invoice) async {
    try {
      final response = await _api.post('invoices', body: invoice.toJson());
      return response['_id'] ?? response['id'];
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      rethrow;
    }
  }

  Future<List<Invoice>> getClientInvoices(String clientId) async {
    try {
      final response = await _api.get('invoices', queryParams: {'clientId': clientId});
      final List<dynamic> data = response;
      return data.map((json) => Invoice.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting client invoices: $e');
      return [];
    }
  }

  Future<List<Invoice>> getAllInvoices() async {
    try {
      final response = await _api.get('invoices');
      final List<dynamic> data = response;
      return data.map((json) => Invoice.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all invoices: $e');
      return [];
    }
  }

  Future<String> generateInvoiceNumber() async {
    final year = DateTime.now().year;
    try {
      final response = await _api.get('invoices/next-number');
      return response['invoiceNumber'] ?? 'INV-$year-0001';
    } catch (e) {
      debugPrint('Error generating invoice number: $e');
      return 'INV-$year-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      await _api.put('invoices/$invoiceId', body: {'status': status});
    } catch (e) {
      debugPrint('Error updating invoice status: $e');
      rethrow;
    }
  }
}
