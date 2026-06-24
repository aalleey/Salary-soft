import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _withDocId(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    data['_id'] = doc.id;
    return data;
  }

  Future<String> recordPayment(Payment payment) async {
    try {
      final docRef = await _firestore.collection('payments').add(payment.toJson());
      return docRef.id;
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    }
  }

  Future<List<Payment>> getClientPayments(String clientId) async {
    try {
      final snapshot = await _firestore.collection('payments')
          .where('clientId', isEqualTo: clientId)
          .get();
      return snapshot.docs.map((doc) => Payment.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting client payments: $e');
      return [];
    }
  }

  Future<List<Payment>> getAllPayments() async {
    try {
      final snapshot = await _firestore.collection('payments').get();
      return snapshot.docs.map((doc) => Payment.fromJson(_withDocId(doc))).toList();
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
