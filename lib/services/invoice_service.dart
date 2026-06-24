import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  factory InvoiceService() => _instance;
  InvoiceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _withDocId(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    data['_id'] = doc.id;
    return data;
  }

  Future<String> createInvoice(Invoice invoice) async {
    try {
      final docRef = await _firestore.collection('invoices').add(invoice.toJson());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      rethrow;
    }
  }

  Future<List<Invoice>> getClientInvoices(String clientId) async {
    try {
      final snapshot = await _firestore.collection('invoices')
          .where('clientId', isEqualTo: clientId)
          .get();
      return snapshot.docs.map((doc) => Invoice.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting client invoices: $e');
      return [];
    }
  }

  Future<List<Invoice>> getAllInvoices() async {
    try {
      final snapshot = await _firestore.collection('invoices').get();
      return snapshot.docs.map((doc) => Invoice.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting all invoices: $e');
      return [];
    }
  }

  Future<String> generateInvoiceNumber() async {
    final year = DateTime.now().year;
    try {
      // In Firestore, creating sequential numbers requires a counter document.
      // We'll use a transaction to safely increment the counter.
      final counterRef = _firestore.collection('counters').doc('invoices_$year');
      final newCounter = await _firestore.runTransaction<int>((transaction) async {
        final snapshot = await transaction.get(counterRef);
        if (!snapshot.exists) {
          transaction.set(counterRef, {'count': 1});
          return 1;
        }
        final newCount = (snapshot.data()?['count'] ?? 0) + 1;
        transaction.update(counterRef, {'count': newCount});
        return newCount;
      });
      return 'INV-$year-${newCounter.toString().padLeft(4, '0')}';
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
