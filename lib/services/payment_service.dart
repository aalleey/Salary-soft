import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/payment.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> recordPayment(Payment payment) async {
    try {
      final docRef = await _firestore.collection('payments').add(payment.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    }
  }

  Future<List<Payment>> getClientPayments(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('client_id', isEqualTo: clientId)
          .orderBy('payment_date', descending: true)
          .get();
      return snapshot.docs.map((doc) => Payment.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error getting client payments: $e');
      return [];
    }
  }

  Future<List<Payment>> getAllPayments() async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .orderBy('payment_date', descending: true)
          .get();
      return snapshot.docs.map((doc) => Payment.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error getting all payments: $e');
      return [];
    }
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({'status': status});
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      rethrow;
    }
  }
}
