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
  const SuperAdminDashboardScreen({super.key});

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'App Owner Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Premium Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2027), // Deep space
                  Color(0xFF203A43), // Teal blue
                  Color(0xFF2C5364), // Cool grey-blue
                ],
              ),
            ),
          ),
          // Decorative glowing orbs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.withValues(alpha: 0.15),
              ),
            ),
          ),
          
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SaaS Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
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
                        Colors.blueAccent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ClientsScreen()),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        'Packages',
                        'Subscription plans',
                        Icons.local_offer,
                        Colors.greenAccent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PackagesScreen()),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        'Subscriptions',
                        'Manage access',
                        Icons.card_membership,
                        Colors.purpleAccent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionsScreen(),
                          ),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        'Payments',
                        'Record & view',
                        Icons.payments,
                        Colors.orangeAccent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        'Invoices',
                        'PDF Invoices',
                        Icons.receipt_long,
                        Colors.tealAccent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InvoicesScreen()),
                        ),
                      ),
                      _buildActionCard(
                        context,
                        'Audit Logs',
                        'System tracking',
                        Icons.security,
                        Colors.redAccent,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuditLogsScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
      splashColor: color.withValues(alpha: 0.3),
      highlightColor: color.withValues(alpha: 0.1),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        blur: 15,
        backgroundOpacity: 0.1,
        borderOpacity: 0.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ],
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
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
