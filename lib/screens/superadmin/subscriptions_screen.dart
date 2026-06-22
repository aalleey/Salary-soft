import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import 'add_edit_subscription_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final SubscriptionService _service = SubscriptionService();
  bool _isLoading = true;
  List<Subscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    try {
      final subs = await _service.getAllSubscriptions();
      setState(() {
        _subscriptions = subs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status, Subscription sub) {
    if (sub.isExpired) return Colors.red;
    switch (status) {
      case 'active': return Colors.green;
      case 'suspended': return Colors.orange;
      case 'cancelled': return Colors.grey;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubscriptions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditSubscriptionScreen()),
          );
          if (result == true) _loadSubscriptions();
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscriptions.isEmpty
              ? const Center(child: Text('No subscriptions found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subscriptions.length,
                  itemBuilder: (context, index) {
                    final sub = _subscriptions[index];
                    final color = _getStatusColor(sub.status, sub);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
                      ),
                      child: ListTile(
                        title: Text('Client ID: ${sub.clientId}'), // You could resolve this to Institute Name later
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Package ID: ${sub.packageId}'),
                            Text('Expires: ${DateFormat('MMM dd, yyyy').format(sub.endDate)}'),
                            if (sub.isExpired && sub.isInGracePeriod)
                              const Text('IN GRACE PERIOD', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            sub.isExpired ? 'EXPIRED' : sub.status.toUpperCase(),
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                          backgroundColor: color,
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditSubscriptionScreen(subscription: sub),
                            ),
                          );
                          if (result == true) _loadSubscriptions();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
