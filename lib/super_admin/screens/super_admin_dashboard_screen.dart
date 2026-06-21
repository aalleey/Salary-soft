import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../auth/models/app_user.dart';
import '../../shared/widgets/role_badge_widget.dart';
import '../../shared/widgets/stat_card_widget.dart';
import '../../screens/login_screen.dart';
import '../../screens/staff_list_screen.dart';
import '../../screens/salary_payment_dashboard_screen.dart';
import '../../screens/attendance_report_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _headerAnim;
  late AnimationController _orb1;
  late AnimationController _orb2;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    )..repeat(reverse: true);
    _orb1 = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _orb2 = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _orb1.dispose();
    _orb2.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
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
            headerAnim: _headerAnim,
            orb1: _orb1,
            orb2: _orb2,
            onLogout: _logout,
          ),
          const _StaffTab(),
          const _ReportsTab(),
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
                accentColor: const Color(0xFF06B6D4),
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: 'Staff',
                index: 1,
                current: _currentIndex,
                accentColor: const Color(0xFF06B6D4),
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              _NavItem(
                icon: Icons.assessment_rounded,
                label: 'Reports',
                index: 2,
                current: _currentIndex,
                accentColor: const Color(0xFF06B6D4),
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
                current: _currentIndex,
                accentColor: const Color(0xFF06B6D4),
                onTap: (i) => setState(() => _currentIndex = i),
              ),
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
  final AnimationController headerAnim;
  final AnimationController orb1;
  final AnimationController orb2;
  final VoidCallback onLogout;

  const _HomeTab({
    required this.headerAnim,
    required this.orb1,
    required this.orb2,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── SliverAppBar ─────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 252,
          pinned: true,
          floating: false,
          backgroundColor: const Color(0xFF0E4F6D),
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: headerAnim,
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(const Color(0xFF0C4A6E),
                              const Color(0xFF0369A1), headerAnim.value)!,
                          Color.lerp(const Color(0xFF0891B2),
                              const Color(0xFF06B6D4), headerAnim.value)!,
                        ],
                      ),
                    ),
                  ),
                ),
                // Orb 1
                AnimatedBuilder(
                  animation: orb1,
                  builder: (_, __) => Positioned(
                    right: -50 + 25 * orb1.value,
                    top: -30 + 15 * orb1.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFF38BDF8).withValues(alpha: 0.18),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ),
                // Orb 2
                AnimatedBuilder(
                  animation: orb2,
                  builder: (_, __) => Positioned(
                    left: -40 + 20 * orb2.value,
                    bottom: 10 + 10 * orb2.value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFF7C3AED).withValues(alpha: 0.12),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                ),
                // Header content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const RoleBadge(
                                role: UserRole.superUser, large: true),
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
                                    onTap: () {}),
                                const SizedBox(width: 8),
                                _HeaderIconBtn(
                                    icon: Icons.logout_rounded,
                                    onTap: onLogout),
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
                          user?.username ?? 'Super Admin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.location_city_rounded,
                                color: Colors.white54, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              user?.assignedCampuses.isNotEmpty == true
                                  ? user!.assignedCampuses.join(', ')
                                  : 'All Campuses',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.calendar_today_rounded,
                                color: Colors.white54, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              DateFormat('MMM d, yyyy').format(DateTime.now()),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
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
                const _SectionTitle(title: 'Overview'),
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
                      label: 'Total Staff',
                      value: '—',
                      icon: Icons.people_rounded,
                      gradient: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                      subtitle: 'Active employees',
                    ),
                    StatCard(
                      label: 'Monthly Salary',
                      value: '—',
                      icon: Icons.payments_rounded,
                      gradient: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                      subtitle: 'This month',
                    ),
                    StatCard(
                      label: 'Advances',
                      value: '—',
                      icon: Icons.account_balance_wallet_rounded,
                      gradient: [Color(0xFFD97706), Color(0xFFF59E0B)],
                      subtitle: 'Pending recovery',
                    ),
                    StatCard(
                      label: 'Campuses',
                      value: '—',
                      icon: Icons.location_city_rounded,
                      gradient: [Color(0xFF059669), Color(0xFF10B981)],
                      subtitle: 'Under management',
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Quick navigation
                const _SectionTitle(title: 'Quick Actions'),
                const SizedBox(height: 14),
                _ActionCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Staff Management',
                  subtitle: 'View, add and edit staff members',
                  gradient: [const Color(0xFF0891B2), const Color(0xFF06B6D4)],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const StaffListScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'Paid Salary Management',
                  subtitle: 'Manage and process employee salaries',
                  gradient: [const Color(0xFF7C3AED), const Color(0xFFA855F7)],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const SalaryPaymentDashboardScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.event_note_rounded,
                  title: 'Attendance Reports',
                  subtitle: 'Staff attendance and absence tracking',
                  gradient: [const Color(0xFF059669), const Color(0xFF10B981)],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AttendanceReportScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Payroll Analytics',
                  subtitle: 'Trends, comparisons and insights',
                  gradient: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
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
// Staff Tab
// ─────────────────────────────────────────────────────────────────────────────

class _StaffTab extends StatelessWidget {
  const _StaffTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.people_rounded,
                  size: 40, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text('Staff Management',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('View and manage your staff',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StaffListScreen()),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open Staff List'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reports Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ReportTile(
            icon: Icons.payments_rounded,
            title: 'Paid Salary Management',
            subtitle: 'Process and manage payments',
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SalaryPaymentDashboardScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _ReportTile(
            icon: Icons.event_note_rounded,
            title: 'Attendance Report',
            subtitle: 'Staff attendance and absences',
            color: const Color(0xFF059669),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const AttendanceReportScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
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
    final user =
        Provider.of<AuthProvider>(context, listen: false).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                (user?.username ?? 'S')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user?.username ?? 'Super Admin',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            const RoleBadge(role: UserRole.superUser, large: true),
            const SizedBox(height: 24),
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
                        user?.assignedCampuses.isNotEmpty == true
                            ? user!.assignedCampuses.join(', ')
                            : 'All Campuses',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.shield_rounded),
                      title: const Text('Access Level'),
                      subtitle: const Text('Campus & Staff Management'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text('Sign Out',
                    style: TextStyle(color: Colors.red)),
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
// Shared small widgets (duplicated from owner for independence)
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? accentColor : Colors.grey, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
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
