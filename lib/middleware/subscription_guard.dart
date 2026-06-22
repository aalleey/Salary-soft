import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';

class SubscriptionGuard extends StatelessWidget {
  final Widget child;
  final bool requireActive;

  const SubscriptionGuard({
    Key? key,
    required this.child,
    this.requireActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subProvider, _) {
        if (subProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Super Admin bypasses all checks
        if (subProvider.authProvider.currentUser?.role == 'super_admin') {
          return child;
        }

        if (subProvider.isFullyLocked || (requireActive && subProvider.isExpired)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 80, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Subscription Expired',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text('Please renew your subscription to continue using SalarySoft.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to payment/contact page
                    },
                    child: const Text('Renew Now'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            if (subProvider.isInGracePeriod && !requireActive)
              Container(
                color: Colors.orange.withOpacity(0.9),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your subscription expired. You are in the grace period. Please renew to avoid access loss.',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
