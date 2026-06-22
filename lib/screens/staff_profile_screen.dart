import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/staff.dart';
import '../models/attendance.dart';
import '../models/salary.dart';
import '../services/firebase_service.dart';
import '../shared/widgets/glass_card_widget.dart';

class StaffProfileScreen extends StatefulWidget {
  final Staff staff;

  const StaffProfileScreen({super.key, required this.staff});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Attendance> _attendanceHistory = [];
  List<Salary> _salaryHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _firebaseService.getStaffAttendance(widget.staff.id),
        _firebaseService.getStaffSalaries(widget.staff.id),
      ]);
      
      if (mounted) {
        setState(() {
          _attendanceHistory = futures[0] as List<Attendance>;
          _salaryHistory = futures[1] as List<Salary>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280.0,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2E0249),
                            Colors.deepPurple,
                            Color(0xFFF806CC),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Hero(
                          tag: 'avatar_${widget.staff.id}',
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: widget.staff.profileImageUrl != null
                                ? NetworkImage(widget.staff.profileImageUrl!)
                                : null,
                            child: widget.staff.profileImageUrl == null
                                ? Text(
                                    widget.staff.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.staff.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.staff.designation != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.staff.designation!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                tabs: const [
                  Tab(text: 'Profile'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Salaries'),
                  Tab(text: 'Breakdown'),
                  Tab(text: 'Documents'),
                ],
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(isDark),
                  _buildAttendanceTab(isDark),
                  _buildSalaryHistoryTab(isDark),
                  _buildSalaryBreakdownTab(isDark),
                  _buildDocumentsTab(isDark),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          title: 'Personal Information',
          icon: Icons.person_outline,
          isDark: isDark,
          children: [
            _buildInfoRow('Father/Husband Name', widget.staff.fatherHusbandName ?? 'N/A'),
            _buildInfoRow('CNIC', widget.staff.cnic ?? 'N/A'),
            _buildInfoRow('Phone Number', widget.staff.phone),
            _buildInfoRow('Home Address', widget.staff.address ?? 'N/A'),
            _buildInfoRow('Emergency Contact', widget.staff.emergencyContact ?? 'N/A'),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Employment Details',
          icon: Icons.work_outline,
          isDark: isDark,
          children: [
            _buildInfoRow('Campus', widget.staff.campus),
            _buildInfoRow('Joining Date', widget.staff.joiningDate ?? 'N/A'),
            _buildInfoRow('Salary Type', widget.staff.salaryType),
            _buildInfoRow('Basic Salary', 'Rs ${NumberFormat.compact().format(widget.staff.salary)}'),
            _buildInfoRow('Bank Account', widget.staff.bankAccount ?? 'N/A'),
            _buildInfoRow('Status', widget.staff.isActive ? 'Active' : 'Deleted/Inactive',
                valueColor: widget.staff.isActive ? Colors.green : Colors.red),
          ],
        ),
        if (widget.staff.notes != null && widget.staff.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Internal Notes',
            icon: Icons.note_alt_outlined,
            isDark: isDark,
            children: [
              Text(
                widget.staff.notes!,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.deepPurple, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(bool isDark) {
    if (_attendanceHistory.isEmpty) {
      return const Center(child: Text('No attendance records found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendanceHistory.length,
      itemBuilder: (context, index) {
        final att = _attendanceHistory[index];
        final monthName = DateFormat('MMMM').format(DateTime(2024, att.month));
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$monthName ${att.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Absents: ${att.absents}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    Text(
                      'Lates: ${att.lates} | Half Leaves: ${att.halfLeaves}',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalaryHistoryTab(bool isDark) {
    if (_salaryHistory.isEmpty) {
      return const Center(child: Text('No salary records found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _salaryHistory.length,
      itemBuilder: (context, index) {
        final salary = _salaryHistory[index];
        final monthName = DateFormat('MMMM').format(DateTime(2024, salary.month));
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$monthName ${salary.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: salary.isPaid ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: salary.isPaid ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Text(
                        salary.status,
                        style: TextStyle(
                          color: salary.isPaid ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Final Salary'),
                    Text(
                      'Rs ${NumberFormat.compact().format(salary.totalSalary)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalaryBreakdownTab(bool isDark) {
    if (_salaryHistory.isEmpty) {
      return const Center(child: Text('No salary records to breakdown.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _salaryHistory.length,
      itemBuilder: (context, index) {
        final salary = _salaryHistory[index];
        final monthName = DateFormat('MMMM').format(DateTime(2024, salary.month));
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Breakdown for $monthName ${salary.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.deepPurple,
                  ),
                ),
                const Divider(height: 24),
                _buildInfoRow('Basic Salary', 'Rs ${NumberFormat.compact().format(salary.basicSalary)}'),
                _buildInfoRow('Absents Deduction', '-Rs ${NumberFormat.compact().format(salary.deduction - salary.advanceAmount)}', valueColor: Colors.red),
                _buildInfoRow('Advances Deducted', '-Rs ${NumberFormat.compact().format(salary.advanceAmount)}', valueColor: Colors.orange),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Payable',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Rs ${NumberFormat.compact().format(salary.totalSalary)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentsTab(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Documents Storage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Firebase Storage integration pending.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
