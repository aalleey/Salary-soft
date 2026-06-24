import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches a user document from Firestore by its unique UID
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserByUid(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Searches for a user document in Firestore by email.
  /// First searches in 'users' collection, then falls back to 'clients' collection.
  /// Supports case-insensitive searching via client-side fallback.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserByEmail(String email) async {
    try {
      // 1. Try exact match in 'users'
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (usersSnapshot.docs.isNotEmpty) {
        return usersSnapshot.docs.first;
      }

      // 2. Try case-insensitive fallback in 'users'
      debugPrint('FirestoreUserService: Exact email match not found in users, trying case-insensitive lookup...');
      final allUsers = await _firestore.collection('users').get();
      for (final doc in allUsers.docs) {
        final uemail = doc.data()['email']?.toString().toLowerCase();
        if (uemail == email.toLowerCase()) {
          return doc;
        }
      }

      // 3. Try exact match in 'clients'
      final clientsSnapshot = await _firestore
          .collection('clients')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (clientsSnapshot.docs.isNotEmpty) {
        return clientsSnapshot.docs.first;
      }

      // 4. Try case-insensitive fallback in 'clients'
      debugPrint('FirestoreUserService: Exact email match not found in clients, trying case-insensitive lookup...');
      final allClients = await _firestore.collection('clients').get();
      for (final doc in allClients.docs) {
        final uemail = doc.data()['email']?.toString().toLowerCase();
        if (uemail == email.toLowerCase()) {
          return doc;
        }
      }
    } catch (e) {
      debugPrint('FirestoreUserService: Error fetching user by email: $e');
    }
    return null;
  }

  /// Searches for a user document in Firestore by username or ownerName.
  /// First searches in 'users' collection (username), then falls back to 'clients' collection (ownerName).
  /// Supports case-insensitive searching via client-side fallback.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserByUsername(String username) async {
    try {
      // 1. Try exact match in 'users'
      final usersSnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (usersSnapshot.docs.isNotEmpty) {
        return usersSnapshot.docs.first;
      }

      // 2. Try case-insensitive fallback in 'users'
      debugPrint('FirestoreUserService: Exact username match not found in users, trying case-insensitive lookup...');
      final allUsers = await _firestore.collection('users').get();
      for (final doc in allUsers.docs) {
        final uname = doc.data()['username']?.toString().toLowerCase();
        if (uname == username.toLowerCase()) {
          return doc;
        }
      }

      // 3. Try exact match in 'clients' (ownerName)
      final clientsSnapshot = await _firestore
          .collection('clients')
          .where('ownerName', isEqualTo: username)
          .limit(1)
          .get();
      if (clientsSnapshot.docs.isNotEmpty) {
        return clientsSnapshot.docs.first;
      }

      // 4. Try case-insensitive fallback in 'clients' (ownerName)
      debugPrint('FirestoreUserService: Exact username match not found in clients, trying case-insensitive lookup...');
      final allClients = await _firestore.collection('clients').get();
      for (final doc in allClients.docs) {
        final uname = doc.data()['ownerName']?.toString().toLowerCase();
        if (uname == username.toLowerCase()) {
          return doc;
        }
      }
    } catch (e) {
      debugPrint('FirestoreUserService: Error fetching user by username: $e');
    }
    return null;
  }

  /// Resolves an identifier (which can be either a username or an email address)
  /// to its Firestore user/client document, performing case-insensitive lookups if needed.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserByIdentifier(String identifier) async {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) {
      return await getUserByEmail(trimmed);
    } else {
      return await getUserByUsername(trimmed);
    }
  }
}
