import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../models/package.dart';
import '../services/subscription_service.dart';
import 'auth_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final SubscriptionService _service = SubscriptionService();

  Subscription? _currentSubscription;
  Package? _currentPackage;
  bool _isLoading = false;

  SubscriptionProvider(this.authProvider) {
    if (authProvider.clientId != null) {
      loadSubscriptionData();
    }
    
    // Listen to auth changes
    authProvider.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (authProvider.clientId != null) {
      loadSubscriptionData();
    } else {
      _currentSubscription = null;
      _currentPackage = null;
      notifyListeners();
    }
  }

  Subscription? get currentSubscription => _currentSubscription;
  Package? get currentPackage => _currentPackage;
  bool get isLoading => _isLoading;

  bool get isActive => _currentSubscription?.status == 'active' && !(_currentSubscription?.isExpired ?? true);
  bool get isExpired => _currentSubscription?.isExpired ?? true;
  bool get isInGracePeriod => _currentSubscription?.isInGracePeriod ?? false;
  bool get isFullyLocked => _currentSubscription?.isFullyLocked ?? true;
  int get daysRemaining => _currentSubscription?.daysUntilExpiry ?? 0;

  Future<void> loadSubscriptionData() async {
    final clientId = authProvider.clientId;
    if (clientId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentSubscription = await _service.getActiveSubscription(clientId);
      if (_currentSubscription != null) {
        _currentPackage = await _service.getPackage(_currentSubscription!.packageId);
      }
    } catch (e) {
      debugPrint('Error loading subscription data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool hasFeature(String feature) {
    if (authProvider.currentUser?.role == 'super_admin') return true;
    if (_currentPackage == null) return false;
    return _currentPackage!.features.contains(feature);
  }

  @override
  void dispose() {
    authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}
