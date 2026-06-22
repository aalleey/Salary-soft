import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/glass_card_widget.dart';
import 'clients_screen.dart';
import 'packages_screen.dart';
import 'subscriptions_screen.dart';
import 'payments_screen.dart';
import 'invoices_screen.dart';
import 'audit_logs_screen.dart';
import '../login_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({Key? key}) : super(key: key);

  void _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SaaS Management',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildActionCard(
                  context,
                  'Clients',
                  'Manage institutes',
                  Icons.business,
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen())),
                ),
                _buildActionCard(
                  context,
                  'Packages',
                  'Subscription plans',
                  Icons.local_offer,
                  Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PackagesScreen())),
                ),
                _buildActionCard(
                  context,
                  'Subscriptions',
                  'Manage access',
                  Icons.card_membership,
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen())),
                ),
                _buildActionCard(
                  context,
                  'Payments',
                  'Record & view',
                  Icons.payments,
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen())),
                ),
                _buildActionCard(
                  context,
                  'Invoices',
                  'PDF Invoices',
                  Icons.receipt_long,
                  Colors.teal,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen())),
                ),
                _buildActionCard(
                  context,
                  'Audit Logs',
                  'System tracking',
                  Icons.security,
                  Colors.red,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      ),
    );
  }
}
