import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';
import '../models/package.dart';
import '../models/subscription.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _withDocId(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    data['_id'] = doc.id;
    return data;
  }

  // --- Clients ---

  Future<List<Client>> getClients() async {
    try {
      final snapshot = await _firestore.collection('clients').get();
      final list = snapshot.docs.map((doc) => Client.fromJson(_withDocId(doc))).toList();
      list.sort((a, b) => a.instituteName.toLowerCase().compareTo(b.instituteName.toLowerCase()));
      return list;
    } catch (e, st) {
      debugPrint('Error getting clients: $e');
      debugPrint(st.toString());
      return [];
    }
  }

  Future<Client?> getClient(String id) async {
    try {
      final doc = await _firestore.collection('clients').doc(id).get();
      if (!doc.exists) return null;
      return Client.fromJson(_withDocId(doc));
    } catch (e) {
      debugPrint('Error getting client: $e');
      return null;
    }
  }

  Future<String> addClient(Client client, {String? password}) async {
    try {
      final body = client.toJson();
      if (password != null && password.isNotEmpty) {
        body['password'] = password; // Note: In production, do not store plain text passwords in Firestore. Use Firebase Auth.
      }
      final docRef = await _firestore.collection('clients').add(body);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding client: $e');
      rethrow;
    }
  }

  Future<void> updateClient(String id, Client client) async {
    try {
      await _firestore.collection('clients').doc(id).update(client.toJson());
    } catch (e) {
      debugPrint('Error updating client: $e');
      rethrow;
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _firestore.collection('clients').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting client: $e');
      rethrow;
    }
  }

  // --- Packages ---

  Future<List<Package>> getPackages() async {
    try {
      final snapshot = await _firestore.collection('packages').get();
      final list = snapshot.docs.map((doc) => Package.fromJson(_withDocId(doc))).toList();
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
      return Package.fromJson(_withDocId(doc));
    } catch (e) {
      debugPrint('Error getting package: $e');
      return null;
    }
  }

  Future<String> addPackage(Package package) async {
    try {
      final docRef = await _firestore.collection('packages').add(package.toJson());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding package: $e');
      rethrow;
    }
  }

  Future<void> updatePackage(String id, Package package) async {
    try {
      await _firestore.collection('packages').doc(id).update(package.toJson());
    } catch (e) {
      debugPrint('Error updating package: $e');
      rethrow;
    }
  }

  // --- Subscriptions ---

  Future<Subscription?> getActiveSubscription(String clientId) async {
    try {
      final snapshot = await _firestore.collection('subscriptions')
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: 'active')
          .get();
          
      if (snapshot.docs.isEmpty) return null;
      final list = snapshot.docs.map((doc) => Subscription.fromJson(_withDocId(doc))).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.first;
    } catch (e) {
      debugPrint('Error getting active subscription: $e');
      return null;
    }
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    try {
      final snapshot = await _firestore.collection('subscriptions').get();
      return snapshot.docs.map((doc) => Subscription.fromJson(_withDocId(doc))).toList();
    } catch (e) {
      debugPrint('Error getting all subscriptions: $e');
      return [];
    }
  }

  Future<String> addSubscription(Subscription sub) async {
    try {
      final docRef = await _firestore.collection('subscriptions').add(sub.toJson());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      rethrow;
    }
  }

  Future<void> updateSubscriptionStatus(String id, String status) async {
    try {
      await _firestore.collection('subscriptions').doc(id).update({'status': status});
    } catch (e) {
      debugPrint('Error updating subscription status: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(String id, Subscription sub) async {
    try {
      await _firestore.collection('subscriptions').doc(id).update(sub.toJson());
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      rethrow;
    }
  }
}
