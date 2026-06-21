import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user.dart';
import '../models/salary.dart';
import '../models/attendance.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';
import '../shared/widgets/stat_card_widget.dart';
import '../shared/widgets/glass_card_widget.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  AnimationController? _animController;
  Animation<double>? _fadeAnimation;

  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true; // Start as true to show loading screen
  List<Salary> _mySalaries = [];
  List<Attendance> _myAttendance = [];
  User? _currentUser;

  // Gradient colors for cards
  final List<List<Color>> _cardGradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)],
    [Color(0xFF11998e), Color(0xFF38ef7d)],
    [Color(0xFFfc4a1a), Color(0xFFf7b733)],
    [Color(0xFF00b4db), Color(0xFF0083b0)],
    [Color(0xFFee0979), Color(0xFFff6a00)],
    [Color(0xFF7F00FF), Color(0xFFE100FF)],
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _animController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _currentUser = authProvider.currentUser;

      if (_currentUser != null) {
        final salaries = await _firebaseService.getStaffSalaries(
          _currentUser!.id,
        );
        final attendance = await _firebaseService.getStaffAttendance(
          _currentUser!.id,
        );

        if (mounted) {
          setState(() {
            _mySalaries = salaries;
            _myAttendance = attendance;
            _isLoading = false;
          });
          _animController?.forward();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? _buildLoadingScreen()
          : CustomScrollView(
              slivers: [
                _buildAppBar(isDark),
                SliverToBoxAdapter(
                  child: _fadeAnimation != null
                      ? FadeTransition(
                          opacity: _fadeAnimation!,
                          child: Column(
                            children: [
                              _buildQuickStats(isDark),
                              _buildTabSection(isDark),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            _buildQuickStats(isDark),
                            _buildTabSection(isDark),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E0249),
            Colors.deepPurple.shade700,
            const Color(0xFFF806CC),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading your dashboard...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            Text(
              _currentUser?.username ?? 'Employee',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2E0249),
                Colors.deepPurple.shade700,
                const Color(0xFFF806CC),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: 30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // User avatar
              Positioned(
                right: 20,
                bottom: 60,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (_currentUser?.username ?? 'E')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white,
              ),
              onPressed: () => themeProvider.toggleTheme(),
              tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadData,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildQuickStats(bool isDark) {
    final totalEarned = _mySalaries.fold<double>(
      0,
      (sum, s) => sum + s.totalSalary,
    );
    final paidCount = _mySalaries.where((s) => s.isPaid).length;
    final totalAbsents = _myAttendance.fold<int>(
      0,
      (sum, a) => sum + a.absents,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.account_balance_wallet,
              label: 'Earned',
              value: NumberFormat.compact().format(totalEarned),
              gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              icon: Icons.check_circle,
              label: 'Paid',
              value: '$paidCount',
              gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatCard(
              icon: Icons.event_busy,
              label: 'Absents',
              value: '$totalAbsents',
              gradient: const [Color(0xFFfc4a1a), Color(0xFFf7b733)],
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildStatCard

  Widget _buildTabSection(bool isDark) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xFF2E0249), Color(0xFFF806CC)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on, size: 20),
                    SizedBox(width: 8),
                    Text('Salary'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 8),
                    Text('Attendance'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: TabBarView(
            controller: _tabController,
            children: [_buildSalaryTab(isDark), _buildAttendanceTab(isDark)],
          ),
        ),
      ],
    );
  }

  Widget _buildSalaryTab(bool isDark) {
    if (_mySalaries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.payments_outlined,
        title: 'No Salary Records',
        subtitle: 'Your salary records will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _mySalaries.length,
      itemBuilder: (context, index) {
        final salary = _mySalaries[index];
        final gradient = _cardGradients[index % _cardGradients.length];
        return _buildSalaryCard(salary, gradient, isDark, index);
      },
    );
  }

  Widget _buildSalaryCard(
    Salary salary,
    List<Color> gradient,
    bool isDark,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 20,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              collapsedBackgroundColor: isDark
                  ? Colors.grey.shade900
                  : Colors.white,
              backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    DateFormat('MMM')
                        .format(DateTime(salary.year, salary.month))
                        .substring(0, 3),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat(
                        'MMMM yyyy',
                      ).format(DateTime(salary.year, salary.month)),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: salary.isPaid
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          salary.isPaid ? Icons.check_circle : Icons.schedule,
                          size: 14,
                          color: salary.isPaid ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          salary.isPaid ? 'Paid' : 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: salary.isPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Rs ${NumberFormat('#,##0').format(salary.totalSalary)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: gradient.first,
                  ),
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade800.withValues(alpha: 0.5)
                        : Colors.grey.shade50,
                  ),
                  child: Column(
                    children: [
                      _buildModernDetailRow(
                        'Basic Salary',
                        salary.basicSalary,
                        Icons.account_balance,
                        Colors.blue,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildModernDetailRow(
                        'Absent Deduction',
                        -salary.deduction + salary.advanceAmount,
                        Icons.remove_circle,
                        Colors.red,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildModernDetailRow(
                        'Advance Deduction',
                        -salary.advanceAmount,
                        Icons.money_off,
                        Colors.orange,
                        isDark,
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Net Salary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradient),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Rs ${NumberFormat('#,##0').format(salary.totalSalary)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (salary.isPaid && salary.paidDate != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade400,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Paid on ${DateFormat('dd MMM yyyy').format(DateTime.parse(salary.paidDate!))}',
                              style: TextStyle(
                                color: Colors.green.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernDetailRow(
    String label,
    double amount,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          'Rs ${NumberFormat('#,##0').format(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: amount < 0 ? Colors.red : color,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab(bool isDark) {
    if (_myAttendance.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today,
        title: 'No Attendance Records',
        subtitle: 'Your attendance records will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _myAttendance.length,
      itemBuilder: (context, index) {
        final record = _myAttendance[index];
        return _buildAttendanceCard(record, isDark, index);
      },
    );
  }

  Widget _buildAttendanceCard(Attendance record, bool isDark, int index) {
    final date = DateTime(record.year, record.month);
    final hasIssues =
        record.absents > 0 || record.lates > 0 || record.halfLeaves > 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasIssues
                          ? [Colors.orange.shade400, Colors.orange.shade600]
                          : [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasIssues ? Icons.warning : Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(date),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasIssues ? 'Has deductions' : 'Perfect attendance!',
                        style: TextStyle(
                          color: hasIssues ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildModernStatBadge(
                    'Absents',
                    record.absents,
                    Icons.event_busy,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModernStatBadge(
                    'Lates',
                    record.lates,
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModernStatBadge(
                    'Half Days',
                    record.halfLeaves,
                    Icons.timelapse,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatBadge(
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: Colors.deepPurple.shade300),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
