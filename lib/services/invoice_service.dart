import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/invoice.dart';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  factory InvoiceService() => _instance;
  InvoiceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createInvoice(Invoice invoice) async {
    try {
      final docRef = await _firestore.collection('invoices').add(invoice.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      rethrow;
    }
  }

  Future<List<Invoice>> getClientInvoices(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .where('client_id', isEqualTo: clientId)
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs.map((doc) => Invoice.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error getting client invoices: $e');
      return [];
    }
  }

  Future<List<Invoice>> getAllInvoices() async {
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs.map((doc) => Invoice.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error getting all invoices: $e');
      return [];
    }
  }

  Future<String> generateInvoiceNumber() async {
    final year = DateTime.now().year;
    try {
      final snapshot = await _firestore
          .collection('invoices')
          .where('invoice_number', isGreaterThanOrEqualTo: 'INV-$year-')
          .where('invoice_number', isLessThanOrEqualTo: 'INV-$year-\uf8ff')
          .orderBy('invoice_number', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'INV-$year-0001';
      }

      final lastInvoiceNumber = snapshot.docs.first.data()['invoice_number'] as String;
      final parts = lastInvoiceNumber.split('-');
      if (parts.length == 3) {
        final lastNumber = int.tryParse(parts[2]) ?? 0;
        final nextNumber = (lastNumber + 1).toString().padLeft(4, '0');
        return 'INV-$year-$nextNumber';
      }
      return 'INV-$year-0001';
    } catch (e) {
      debugPrint('Error generating invoice number: $e');
      return 'INV-$year-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({'status': status});
    } catch (e) {
      debugPrint('Error updating invoice status: $e');
      rethrow;
    }
  }
}
