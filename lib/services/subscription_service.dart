import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../models/package.dart';
import '../models/subscription.dart';
import 'api_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final ApiService _api = ApiService();

  // --- Clients ---

  Future<List<Client>> getClients() async {
    try {
      final response = await _api.get('clients');
      final List<dynamic> data = response;
      final list = data.map((json) => Client.fromJson(json)).toList();
      list.sort((a, b) => a.instituteName.toLowerCase().compareTo(b.instituteName.toLowerCase()));
      return list;
    } catch (e) {
      debugPrint('Error getting clients: $e');
      return [];
    }
  }

  Future<Client?> getClient(String id) async {
    try {
      final response = await _api.get('clients/$id');
      return Client.fromJson(response);
    } catch (e) {
      debugPrint('Error getting client: $e');
      return null;
    }
  }

  Future<String> addClient(Client client, {String? password}) async {
    try {
      final body = client.toJson();
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }
      final response = await _api.post('clients', body: body);
      return response['_id'] ?? response['id'];
    } catch (e) {
      debugPrint('Error adding client: $e');
      rethrow;
    }
  }

  Future<void> updateClient(String id, Client client) async {
    try {
      await _api.put('clients/$id', body: client.toJson());
    } catch (e) {
      debugPrint('Error updating client: $e');
      rethrow;
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _api.delete('clients/$id');
    } catch (e) {
      debugPrint('Error deleting client: $e');
      rethrow;
    }
  }

  // --- Packages ---

  Future<List<Package>> getPackages() async {
    try {
      final response = await _api.get('packages');
      final List<dynamic> data = response;
      final list = data.map((json) => Package.fromJson(json)).toList();
      list.sort((a, b) => a.price.compareTo(b.price));
      return list;
    } catch (e) {
      debugPrint('Error getting packages: $e');
      return [];
    }
  }

  Future<Package?> getPackage(String id) async {
    try {
      final response = await _api.get('packages/$id');
      return Package.fromJson(response);
    } catch (e) {
      debugPrint('Error getting package: $e');
      return null;
    }
  }

  Future<String> addPackage(Package package) async {
    try {
      final response = await _api.post('packages', body: package.toJson());
      return response['_id'] ?? response['id'];
    } catch (e) {
      debugPrint('Error adding package: $e');
      rethrow;
    }
  }

  Future<void> updatePackage(String id, Package package) async {
    try {
      await _api.put('packages/$id', body: package.toJson());
    } catch (e) {
      debugPrint('Error updating package: $e');
      rethrow;
    }
  }

  // --- Subscriptions ---

  Future<Subscription?> getActiveSubscription(String clientId) async {
    try {
      final response = await _api.get('subscriptions', queryParams: {'clientId': clientId, 'status': 'active'});
      final List<dynamic> data = response;
      if (data.isEmpty) return null;
      final list = data.map((json) => Subscription.fromJson(json)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.first;
    } catch (e) {
      debugPrint('Error getting active subscription: $e');
      return null;
    }
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    try {
      final response = await _api.get('subscriptions');
      final List<dynamic> data = response;
      return data.map((json) => Subscription.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all subscriptions: $e');
      return [];
    }
  }

  Future<String> addSubscription(Subscription sub) async {
    try {
      final response = await _api.post('subscriptions', body: sub.toJson());
      return response['_id'] ?? response['id'];
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      rethrow;
    }
  }

  Future<void> updateSubscriptionStatus(String id, String status) async {
    try {
      await _api.put('subscriptions/$id', body: {'status': status});
    } catch (e) {
      debugPrint('Error updating subscription status: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(String id, Subscription sub) async {
    try {
      await _api.put('subscriptions/$id', body: sub.toJson());
    } catch (e) {
      debugPrint('Error updating subscription: $e');
      rethrow;
    }
  }
}
