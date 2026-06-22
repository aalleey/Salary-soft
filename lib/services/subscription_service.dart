import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../models/package.dart';
import '../models/subscription.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Clients ---

  Future<List<Client>> getClients() async {
    try {
      final snapshot = await _firestore
          .collection('clients')
          .where('is_deleted', isEqualTo: false)
          .get();
      final list = snapshot.docs.map((doc) => Client.fromFirestore(doc.data(), doc.id)).toList();
      list.sort((a, b) => a.instituteName.toLowerCase().compareTo(b.instituteName.toLowerCase()));
      return list;
    } catch (e) {
      debugPrint('Error getting clients: $e');
      return [];
    }
  }

  Future<Client?> getClient(String id) async {
    try {
      final doc = await _firestore.collection('clients').doc(id).get();
      if (!doc.exists) return null;
      return Client.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error getting client: $e');
      return null;
    }
  }

  Future<String> addClient(Client client) async {
    try {
      final docRef = await _firestore.collection('clients').add(client.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding client: $e');
      rethrow;
    }
  }

  Future<void> updateClient(String id, Client client) async {
    try {
      await _firestore.collection('clients').doc(id).update(client.toFirestore());
    } catch (e) {
      debugPrint('Error updating client: $e');
      rethrow;
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _firestore.collection('clients').doc(id).update({
        'is_deleted': true,
        'deleted_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error deleting client: $e');
      rethrow;
    }
  }

  // --- Packages ---

  Future<List<Package>> getPackages() async {
    try {
      final snapshot = await _firestore
          .collection('packages')
          .where('is_active', isEqualTo: true)
          .get();
      final list = snapshot.docs.map((doc) => Package.fromFirestore(doc.data(), doc.id)).toList();
      list.sort((a, b) => a.price.compareTo(b.price));
      return list;
    } catch (e) {
      debugPrint('Error getting packages: $e');
      return [];
    }
  }

  Future<Package?> getPackage(String id) async {
    try {
      final doc = await _firestore.collection('packages').doc(id).get();
      if (!doc.exists) return null;
      return Package.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error getting package: $e');
      return null;
    }
  }

  Future<String> addPackage(Package package) async {
    try {
      final docRef = await _firestore.collection('packages').add(package.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding package: $e');
      rethrow;
    }
  }

  Future<void> updatePackage(String id, Package package) async {
    try {
      await _firestore.collection('packages').doc(id).update(package.toFirestore());
    } catch (e) {
      debugPrint('Error updating package: $e');
      rethrow;
    }
  }

  // --- Subscriptions ---

  Future<Subscription?> getActiveSubscription(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('client_id', isEqualTo: clientId)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      final list = snapshot.docs.map((doc) => Subscription.fromFirestore(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.first;
    } catch (e) {
      debugPrint('Error getting active subscription: $e');
      return null;
    }
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs.map((doc) => Subscription.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      debugPrint('Error getting all subscriptions: $e');
      return [];
    }
  }

  Future<String> addSubscription(Subscription sub) async {
    try {
      // Deactivate older subscriptions
      final existing = await _firestore
          .collection('subscriptions')
          .where('client_id', isEqualTo: sub.clientId)
          .where('status', isEqualTo: 'active')
          .get();
          
      for (var doc in existing.docs) {
        await doc.reference.update({'status': 'expired'});
      }

      final docRef = await _firestore.collection('subscriptions').add(sub.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      rethrow;
    }
  }

  Future<void> updateSubscriptionStatus(String id, String status) async {
    try {
      await _firestore.collection('subscriptions').doc(id).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating subscription status: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(String id, Subscription sub) async {
    try {
      await _firestore.collection('subscriptions').doc(id).update(sub.toFirestore());
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      rethrow;
    }
  }
}
