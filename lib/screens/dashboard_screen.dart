import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../auth/models/app_user.dart';
import '../providers/theme_provider.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';
import 'staff_list_screen.dart';
import 'attendance_screen.dart';
import 'advance_screen.dart';
import 'salary_payment_dashboard_screen.dart';
import 'manage_campuses_screen.dart';
import 'manage_users_screen.dart';
import '../shared/widgets/stat_card_widget.dart';
import '../shared/widgets/glass_card_widget.dart';
import 'attendance_report_screen.dart';
import 'add_edit_user_screen.dart';
import '../middleware/subscription_guard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
          ),
        );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final activeCampus = authProvider.activeCampus;
      final data = await _firebaseService.getDashboardData(
        campus: activeCampus,
      );

      final history = await _fetchSalaryHistory(activeCampus);

      if (mounted) {
        setState(() {
          _dashboardData = {
            'stats': {
              'total_staff': data['total_staff'] ?? 0,
              'total_paid': data['total_salary_amount'] ?? 0.0,
              'total_absents': data['total_absents'] ?? 0,
              'total_advances_count': data['total_advances_count'] ?? 0,
            },
            'history': history,
          };
          _isLoading = false;
        });
        _controller.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<List<double>> _fetchSalaryHistory(String? campus) async {
    List<double> history = [];
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final salaries = await _firebaseService.getSalaries(
        month: month.month,
        year: month.year,
        campus: campus,
      );
      final total = salaries
          .where((s) => s.isPaid)
          .fold(0.0, (sum, s) => sum + s.totalSalary);
      history.add(total);
    }
    return history;
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SubscriptionGuard(
      requireActive: false,
      child: Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDashboardData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: Colors.deepPurple,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(user, isDark, authProvider),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              _buildSectionTitle('Overview'),
                              const SizedBox(height: 16),
                              _buildStatsGrid(),
                              const SizedBox(height: 32),
                              if (_dashboardData?['history'] != null) ...[
                                _buildSectionTitle('Salary Trends'),
                                const SizedBox(height: 16),
                                _buildSalaryTrendChart(),
                                const SizedBox(height: 32),
                              ],
                              _buildSectionTitle('Quick Actions'),
                              const SizedBox(height: 16),
                              _buildQuickActionsGrid(authProvider.activeCampus),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _buildQuickActionFAB(),
    ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildAppBar(dynamic user, bool isDark, AuthProvider authProvider) {
    final activeCampus = authProvider.activeCampus;
    final userRole = authProvider.userRole;
    final assignedCampuses = user?.assignedCampuses ?? <String>[];
    
    final bool canSwitchCampus = (userRole == UserRole.admin || userRole == UserRole.superUser) && assignedCampuses.length > 1;
    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient with Curve
            ClipPath(
              clipper: _DashboardHeaderClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2E0249), // Deep Purple
                      Colors.deepPurple.shade700,
                      const Color(0xFFF806CC), // Magenta accent
                    ],
                  ),
                ),
              ),
            ),
            // Decorative Circles
            Positioned(
              right: -100,
              top: -50,
              child: CircleAvatar(
                radius: 130,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              left: -50,
              top: 80,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'MMM d, yyyy',
                                ).format(DateTime.now()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Profile Image / Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Text(
                              (user?.username?.isNotEmpty == true ? user!.username![0] : 'A').toUpperCase(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.username ?? 'Admin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (canSwitchCampus)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: PopupMenuButton<String?>(
                          initialValue: activeCampus,
                          onSelected: (campus) {
                            authProvider.setActiveCampus(campus);
                            _loadDashboardData();
                          },
                          offset: const Offset(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.business, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  activeCampus ?? 'Select Campus',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (BuildContext context) {
                            final items = <PopupMenuItem<String?>>[
                              const PopupMenuItem<String?>(
                                value: null,
                                child: Text('All Campuses'),
                              ),
                            ];
                            items.addAll(assignedCampuses.map((String c) {
                              return PopupMenuItem<String?>(
                                value: c,
                                child: Text(c),
                              );
                            }));
                            return items;
                          },
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userRole == UserRole.superUser
                              ? 'Super User Dashboard'
                              : '${activeCampus ?? "Admin"} Campus',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          itemBuilder: (context) {
            final themeProvider = Provider.of<ThemeProvider>(
              context,
              listen: false,
            );
            return <PopupMenuEntry>[
              PopupMenuItem(
                onTap: () => themeProvider.toggleTheme(),
                child: ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: Colors.amber,
                  ),
                  title: Text(
                    themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: _handleLogout,
                child: const ListTile(
                  leading: Icon(Icons.logout_rounded, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ];
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = _dashboardData?['stats'];
    if (stats == null) return const SizedBox();

    return StaggeredGridAnimation(
      controller: _controller,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
        children: [
          StatCard(
            label: 'Total Staff',
            value: stats['total_staff']?.toString() ?? '0',
            icon: Icons.people_alt_rounded,
            gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
          StatCard(
            label: 'Paid Salary',
            value: 'Rs ${NumberFormat.compact().format(stats['total_paid'] ?? 0)}',
            icon: Icons.payments_rounded,
            gradient: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
          ),
          StatCard(
            label: 'Absents',
            value: '${stats['total_absents'] ?? 0}',
            icon: Icons.cancel_presentation_rounded,
            gradient: const [Color(0xFFff758c), Color(0xFFff7eb3)],
          ),
          StatCard(
            label: 'Advances',
            value: stats['total_advances_count']?.toString() ?? '0',
            icon: Icons.wallet_rounded,
            gradient: const [Color(0xFFf6d365), Color(0xFFfda085)],
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryTrendChart() {
    final history = _dashboardData!['history'] as List<double>;
    if (history.every((val) => val == 0)) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 152,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_graph_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text(
                  'No salary history available yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final maxY = history.reduce(max);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 172,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= 6) return const SizedBox();
                  final date = DateTime.now().subtract(
                    Duration(days: (5 - index) * 30),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MMM').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 5,
          minY: 0,
          maxY: maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                history.length,
                (index) => FlSpot(index.toDouble(), history[index]),
              ),
              isCurved: true,
              color: Colors.deepPurple,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.deepPurple,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.deepPurple.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }



  Widget _buildQuickActionFAB() {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildQuickActionSheet(),
        );
      },
      backgroundColor: Colors.deepPurple,
      child: const Icon(Icons.add_rounded, size: 32),
    );
  }

  Widget _buildQuickActionSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            'Add New Staff',
            Icons.person_add_rounded,
            Colors.blue,
            () {
              Navigator.pop(context);
              // Navigate to Add Staff
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AddEditUserScreen(), // Placeholder if Staff Add screen name differs
                ),
              );
            },
          ),
          _buildActionTile(
            'New Advance',
            Icons.monetization_on_rounded,
            Colors.orange,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdvanceScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  Widget _buildQuickActionsGrid(String? userCampus) {
    final isSuperAdmin = userCampus == null || userCampus.isEmpty;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final List<Widget> actions = [
      if (isSuperAdmin) ...[
        _buildGlassyActionCard(
          'Campuses',
          'Manage Locations',
          Icons.business_rounded,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageCampusesScreen()),
          ),
        ),
        _buildGlassyActionCard(
          'Users',
          'Manage Access',
          Icons.admin_panel_settings_rounded,
          Colors.deepPurple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
          ),
        ),
      ],
      if (authProvider.hasPermission('view_staff'))
        _buildGlassyActionCard(
          'Staff',
          'Directory',
          Icons.group_add_rounded,
          Colors.indigo,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StaffListScreen()),
          ),
        ),
      if (authProvider.hasPermission('add_attendance') || authProvider.hasPermission('edit_attendance'))
        _buildGlassyActionCard(
          'Attendance',
          'Mark Today',
          Icons.calendar_month_rounded,
          Colors.teal,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceScreen()),
          ),
        ),
      if (authProvider.hasPermission('export_reports') || authProvider.hasPermission('view_salary_reports'))
        _buildGlassyActionCard(
          'Report',
          'View Attendance',
          Icons.fact_check_rounded,
          Colors.cyan,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
          ),
        ),
      if (authProvider.hasPermission('calculate_salary'))
        _buildGlassyActionCard(
          'Paid Salary',
          'Calculate & Pay',
          Icons.payments_rounded,
          Colors.pink,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SalaryPaymentDashboardScreen()),
          ),
        ),
      if (authProvider.hasPermission('manage_advances'))
        _buildGlassyActionCard(
          'Advances',
          'Manage Loans',
          Icons.card_giftcard_rounded,
          Colors.deepOrange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdvanceScreen()),
          ),
        ),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: actions.map((widget) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          child: widget,
        );
      }).toList(),
    );
  }

  Widget _buildGlassyActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    final firstControlPoint = Offset(size.width / 4, size.height);
    final firstEndPoint = Offset(size.width / 2, size.height);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(
      size.width - (size.width / 4),
      size.height,
    );
    final secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class StaggeredGridAnimation extends StatelessWidget {
  final Widget child;
  final AnimationController controller;

  const StaggeredGridAnimation({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, childWidget) {
        return Transform.translate(
          offset: Offset(0, 50.0 * (1 - controller.value)),
          child: Opacity(opacity: controller.value, child: childWidget),
        );
      },
      child: child,
    );
  }
}
