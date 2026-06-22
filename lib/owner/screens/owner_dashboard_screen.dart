import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../auth/models/app_user.dart';
import '../../shared/widgets/role_badge_widget.dart';
import '../../shared/widgets/stat_card_widget.dart';
import '../../screens/login_screen.dart';
import '../../screens/manage_users_screen.dart';
import '../../screens/manage_campuses_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _headerController;
  late AnimationController _orb1;
  late AnimationController _orb2;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    _orb1 = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    )..repeat(reverse: true);
    _orb2 = AnimationController(
      duration: const Duration(seconds: 11),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _orb1.dispose();
    _orb2.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            orb1: _orb1,
            orb2: _orb2,
            headerAnim: _headerController,
            onLogout: _logout,
          ),
          const _UsersTab(),
          const _AnalyticsTab(),
          const _SettingsTab(),
          _ProfileTab(onLogout: _logout),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Home',
                  index: 0,
                  current: _currentIndex,
                  accentColor: const Color(0xFFF806CC),
                  onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(
                  icon: Icons.group_rounded,
                  label: 'Users',
                  index: 1,
                  current: _currentIndex,
                  accentColor: const Color(0xFFF806CC),
                  onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  index: 2,
                  current: _currentIndex,
                  accentColor: const Color(0xFFF806CC),
                  onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  index: 3,
                  current: _currentIndex,
                  accentColor: const Color(0xFFF806CC),
                  onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 4,
                  current: _currentIndex,
                  accentColor: const Color(0xFFF806CC),
                  onTap: (i) => setState(() => _currentIndex = i)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Tab
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final AnimationController orb1;
  final AnimationController orb2;
  final AnimationController headerAnim;
  final VoidCallback onLogout;

  const _HomeTab({
    required this.orb1,
    required this.orb2,
    required this.headerAnim,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Gradient App Bar ─────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          floating: false,
          backgroundColor: const Color(0xFF2E0249),
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Animated gradient background
                AnimatedBuilder(
                  animation: headerAnim,
                  builder: (context, child) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(const Color(0xFF1A0533),
                              const Color(0xFF3B0764), headerAnim.value)!,
                          Color.lerp(const Color(0xFF7C3AED),
                              const Color(0xFFF806CC), headerAnim.value * 0.5)!,
                        ],
                      ),
                    ),
                  ),
                ),
                // Orbs
                AnimatedBuilder(
                  animation: orb1,
                  builder: (context, child) => Positioned(
                    right: -60 + 30 * orb1.value,
                    top: -40 + 20 * orb1.value,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFFF806CC).withValues(alpha: 0.2),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: orb2,
                  builder: (context, child) => Positioned(
                    left: -30 + 20 * orb2.value,
                    bottom: 20 + 15 * orb2.value,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFF7C3AED).withValues(alpha: 0.15),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ),
                // Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RoleBadge(role: UserRole.superAdmin, large: true),
                            Row(
                              children: [
                                Consumer<ThemeProvider>(
                                  builder: (context, theme, child) {
                                    return _HeaderIconBtn(
                                      icon: theme.isDarkMode
                                          ? Icons.light_mode_rounded
                                          : Icons.dark_mode_rounded,
                                      onTap: () => theme.toggleTheme(),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _HeaderIconBtn(
                                  icon: Icons.notifications_outlined,
                                  onTap: () {},
                                ),
                                const SizedBox(width: 8),
                                _HeaderIconBtn(
                                  icon: Icons.logout_rounded,
                                  onTap: onLogout,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          _greeting(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.username ?? 'App Owner',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy')
                              .format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                _SectionTitle(title: 'Overview'),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.88,
                  children: const [
                    StatCard(
                      label: 'Total Users',
                      value: '—',
                      icon: Icons.group_rounded,
                      gradient: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                      subtitle: 'All system users',
                    ),
                    StatCard(
                      label: 'Super Admins',
                      value: '—',
                      icon: Icons.shield_rounded,
                      gradient: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                      subtitle: 'Active accounts',
                    ),
                    StatCard(
                      label: 'Admins',
                      value: '—',
                      icon: Icons.manage_accounts_rounded,
                      gradient: [Color(0xFF059669), Color(0xFF10B981)],
                      subtitle: 'Campus admins',
                    ),
                    StatCard(
                      label: 'Campuses',
                      value: '—',
                      icon: Icons.location_city_rounded,
                      gradient: [Color(0xFFD97706), Color(0xFFF59E0B)],
                      subtitle: 'Registered',
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Management
                _SectionTitle(title: 'Management'),
                const SizedBox(height: 14),
                _ActionCard(
                  icon: Icons.shield_rounded,
                  title: 'Manage Super Admins',
                  subtitle: 'Create, edit or deactivate super admin accounts',
                  gradient: [const Color(0xFF0891B2), const Color(0xFF06B6D4)],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ManageUsersScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.location_city_rounded,
                  title: 'Manage Campuses',
                  subtitle: 'Add, rename or remove campus locations',
                  gradient: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ManageCampusesScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.analytics_rounded,
                  title: 'Full System Analytics',
                  subtitle: 'View payroll, attendance and performance metrics',
                  gradient: [const Color(0xFF7C3AED), const Color(0xFFF806CC)],
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.history_rounded,
                  title: 'Activity Log',
                  subtitle: 'Audit trail of all system actions',
                  gradient: [const Color(0xFF4B5563), const Color(0xFF6B7280)],
                  onTap: () {},
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Users Tab
// ─────────────────────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Users'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            onPressed: () {},
            color: const Color(0xFFF806CC),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined,
                size: 72, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'User Management',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Manage all system users here',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open User Manager'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics Tab
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFF806CC)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.analytics_rounded,
                  size: 44, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text('System Analytics',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Advanced charts and metrics coming soon',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings Tab
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsTile(
            icon: Icons.palette_rounded,
            title: 'Appearance',
            subtitle: 'Theme, colours, fonts',
            color: const Color(0xFF7C3AED),
          ),
          _SettingsTile(
            icon: Icons.security_rounded,
            title: 'Security',
            subtitle: 'Auth settings, session policy',
            color: const Color(0xFF10B981),
          ),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Email and push settings',
            color: const Color(0xFFF59E0B),
          ),
          _SettingsTile(
            icon: Icons.backup_rounded,
            title: 'Backup & Export',
            subtitle: 'Data export, database backup',
            color: const Color(0xFF06B6D4),
          ),
          _SettingsTile(
            icon: Icons.info_rounded,
            title: 'About',
            subtitle: 'Version 1.0.0 · SalarySoft',
            color: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final VoidCallback onLogout;
  const _ProfileTab({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;


    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFF806CC)],
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                (user?.username ?? 'O')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.username ?? 'App Owner',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            const RoleBadge(role: UserRole.superAdmin, large: true),
            const SizedBox(height: 28),

            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_rounded),
                      title: const Text('User ID'),
                      subtitle: Text(user?.id ?? '—'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_city_rounded),
                      title: const Text('Campus'),
                      subtitle: Text(
                          user?.assignedCampuses.isEmpty ?? true ? 'All Campuses' : user!.assignedCampuses.join(', ')),
                    ),
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_rounded),
                      title: const Text('Access Level'),
                      subtitle: const Text('Full System Access'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final Color accentColor;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = current == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? accentColor : Colors.grey, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? accentColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}
