import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../models/salary.dart';
import '../models/campus.dart';
import '../shared/widgets/stat_card_widget.dart';
import '../shared/widgets/glass_card_widget.dart';
import 'widgets/salary_payment_bottom_sheet.dart';

class SalaryPaymentDashboardScreen extends StatefulWidget {
  const SalaryPaymentDashboardScreen({super.key});

  @override
  State<SalaryPaymentDashboardScreen> createState() => _SalaryPaymentDashboardScreenState();
}

class _SalaryPaymentDashboardScreenState extends State<SalaryPaymentDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String _searchQuery = '';
  String _filterStatus = 'All'; // All, Paid, Partial Paid, Pending
  
  bool _isSuperAdmin = false;
  String? _userCampus;
  List<Campus> _campuses = [];
  Map<String, String> _campusMap = {};
  String _selectedCampusId = 'All Campuses';
  
  final Set<String> _selectedSalaryIds = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _userCampus = authProvider.activeCampus;
    _isSuperAdmin = _userCampus == null || _userCampus!.isEmpty;

    if (_isSuperAdmin) {
      try {
        final campuses = await _firebaseService.getCampuses();
        if (mounted) {
          setState(() {
            _campuses = campuses;
            _campusMap = {for (var c in campuses) c.id: c.name};
            _selectedCampusId = 'All Campuses';
          });
        }
      } catch (e) {
        // error
      }
    } else {
      _selectedCampusId = _userCampus ?? 'All Campuses';
    }
  }

  String? get _effectiveCampus {
    if (!_isSuperAdmin) return _userCampus;
    if (_selectedCampusId == 'All Campuses') return null;
    return _selectedCampusId;
  }

  List<Salary> _filterSalaries(List<Salary> salaries) {
    return salaries.where((s) {
      if (_searchQuery.isNotEmpty) {
        if (!s.staffName.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      if (_filterStatus != 'All') {
        if (s.statusText != _filterStatus) {
          return false;
        }
      }
      return true;
    }).toList()..sort((a, b) => a.staffName.compareTo(b.staffName));
  }

  void _showCampusSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(24),
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('All Campuses'),
              trailing: _selectedCampusId == 'All Campuses'
                  ? const Icon(Icons.check, color: Colors.deepPurple)
                  : null,
              onTap: () {
                setState(() => _selectedCampusId = 'All Campuses');
                Navigator.pop(context);
              },
            ),
            ..._campuses.map(
              (c) => ListTile(
                title: Text(c.name),
                trailing: _selectedCampusId == c.id
                    ? const Icon(Icons.check, color: Colors.deepPurple)
                    : null,
                onTap: () {
                  setState(() => _selectedCampusId = c.id);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleRecalculate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Recalculate Salaries?'),
        content: Text(
          'This will update salary calculations for all staff in ${_effectiveCampus ?? 'all campuses'} for ${DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth))}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Recalculate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recalculating...')),
    );

    try {
      await _firebaseService.batchRecalculateSalaries(
        _selectedMonth,
        _selectedYear,
        campus: _effectiveCampus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recalculation complete!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Selection mode is always active via visible checkboxes

  void _toggleSalarySelection(String id) {
    setState(() {
      if (_selectedSalaryIds.contains(id)) {
        _selectedSalaryIds.remove(id);
      } else {
        _selectedSalaryIds.add(id);
      }
    });
  }

  Future<void> _handleRecalculateSelected() async {
    if (_selectedSalaryIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Calculate Selected?'),
        content: Text(
          'Recalculate salaries for the ${_selectedSalaryIds.length} selected staff members?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Calculate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calculating selected salaries...')),
    );

    try {
      final salaries = await _firebaseService.getSalaries(
        month: _selectedMonth,
        year: _selectedYear,
        campus: _effectiveCampus,
      );
      
      final selectedSalaries = salaries.where((s) => _selectedSalaryIds.contains(s.id)).toList();
      
      for (final salary in selectedSalaries) {
        await _firebaseService.recalculateAndSaveSalary(
          salary.staffId,
          _selectedMonth,
          _selectedYear,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calculation complete for selected staff!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _selectedSalaryIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: StreamBuilder<List<Salary>>(
        stream: _firebaseService.getSalariesStream(
          month: _selectedMonth,
          year: _selectedYear,
          campus: _effectiveCampus,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allSalaries = snapshot.data ?? [];
          final filteredSalaries = _filterSalaries(allSalaries);

          final totalEmployees = allSalaries.length;
          final totalPaid = allSalaries.fold<double>(0, (sum, s) => sum + s.paidAmount);
          final totalAdvances = allSalaries.fold<double>(0, (sum, s) => sum + s.advanceAmount);
          final totalPending = allSalaries.fold<double>(0, (sum, s) => sum + s.remainingAmount);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 140.0,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: ClipPath(
                  clipper: _PaymentHeaderClipper(),
                  child: Container(
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
                        Positioned(
                          right: -30,
                          top: -30,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, bottom: 20, right: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedSalaryIds.isNotEmpty 
                                      ? '${_selectedSalaryIds.length} Selected' 
                                      : 'Salary Payments',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (_selectedSalaryIds.isNotEmpty) ...[
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                                        tooltip: 'Clear Selection',
                                        onPressed: () {
                                          setState(() {
                                            _selectedSalaryIds.clear();
                                          });
                                        },
                                      ),
                                    ] else ...[
                                      IconButton(
                                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                        tooltip: 'Recalculate All',
                                        onPressed: _handleRecalculate,
                                      ),
                                    ],
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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Stats Row 1
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Total Paid', 
                              value: 'Rs ${NumberFormat.compact().format(totalPaid)}', 
                              icon: Icons.payments_rounded, 
                              gradient: [Colors.green.shade400, Colors.green.shade700]
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              label: 'Pending', 
                              value: 'Rs ${NumberFormat.compact().format(totalPending)}', 
                              icon: Icons.pending_actions_rounded, 
                              gradient: [Colors.orange.shade400, Colors.orange.shade700]
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Stats Row 2
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Employees', 
                              value: '$totalEmployees', 
                              icon: Icons.people_alt_rounded, 
                              gradient: [Colors.blue.shade400, Colors.blue.shade700]
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              label: 'Advances', 
                              value: 'Rs ${NumberFormat.compact().format(totalAdvances)}', 
                              icon: Icons.money_off_rounded, 
                              gradient: [Colors.purple.shade400, Colors.purple.shade700]
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Search and Filter
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search employee...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth)),
                              icon: Icons.calendar_month_rounded,
                              isDark: isDark,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(_selectedYear, _selectedMonth),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _selectedYear = date.year;
                                    _selectedMonth = date.month;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            if (_isSuperAdmin) ...[
                              _buildFilterChip(
                                label: _selectedCampusId == 'All Campuses'
                                    ? 'All Campuses'
                                    : (_campusMap[_selectedCampusId] ?? _selectedCampusId),
                                icon: Icons.business_rounded,
                                isDark: isDark,
                                onTap: _showCampusSelector,
                              ),
                              const SizedBox(width: 8),
                            ],
                            _buildFilterChip(
                              label: _filterStatus,
                              icon: Icons.filter_list_rounded,
                              isDark: isDark,
                              onTap: () {
                                setState(() {
                                  if (_filterStatus == 'All') {
                                    _filterStatus = 'Pending';
                                  } else if (_filterStatus == 'Pending') {
                                    _filterStatus = 'Partial Paid';
                                  } else if (_filterStatus == 'Partial Paid') {
                                    _filterStatus = 'Paid';
                                  } else {
                                    _filterStatus = 'All';
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (filteredSalaries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('No records found', style: TextStyle(color: theme.disabledColor)),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final salary = filteredSalaries[index];
                      return _buildPaymentCard(salary, context, isDark, theme);
                    },
                    childCount: filteredSalaries.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: _selectedSalaryIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _handleRecalculateSelected,
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Calculate Selected (${_selectedSalaryIds.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildPaymentCard(Salary salary, BuildContext context, bool isDark, ThemeData theme) {
    final hasAdvance = salary.advanceAmount > 0;
    final isOverpaid = salary.paidAmount > salary.totalSalary;
    final remaining = salary.remainingAmount;

    final isSelected = _selectedSalaryIds.contains(salary.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.deepPurple, width: 2)
              : null,
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(18),
          borderRadius: 20,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => SalaryPaymentBottomSheet(salary: salary),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {}, // swallows tap to avoid triggering bottom sheet onTap
                      child: Checkbox(
                        value: isSelected,
                        activeColor: Colors.deepPurple,
                        onChanged: (_) => _toggleSalarySelection(salary.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: salary.statusColor.withValues(alpha: 0.15),
                      child: Text(
                        salary.staffName.isNotEmpty ? salary.staffName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: salary.statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            salary.staffName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _campusMap[salary.campus] ?? salary.campus ?? 'Unknown Campus',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: salary.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      salary.statusText,
                      style: TextStyle(
                        color: salary.statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCardStat(
                    'Net Salary',
                    'Rs ${NumberFormat.compact().format(salary.totalSalary)}',
                    color: Colors.blue,
                  ),
                  _buildCardStat(
                    'Paid',
                    'Rs ${NumberFormat.compact().format(salary.paidAmount)}',
                    color: Colors.green,
                  ),
                  _buildCardStat(
                    'Remaining',
                    'Rs ${NumberFormat.compact().format(remaining)}',
                    color: Colors.orange,
                    isBold: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    salary.salaryType == 'hourly'
                        ? Icons.access_time_rounded
                        : salary.salaryType == 'lecture_based'
                            ? Icons.school_rounded
                            : Icons.calendar_month_rounded,
                    size: 14,
                    color: Colors.deepPurple.shade300,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (salary.calculationDetails != null && salary.calculationDetails!.isNotEmpty)
                          ? salary.calculationDetails!
                          : salary.salaryType == 'hourly'
                              ? '${salary.totalHours.toStringAsFixed(1)} hours @ Rs ${salary.hourlyRate.toStringAsFixed(0)}/hr'
                              : salary.salaryType == 'lecture_based'
                                  ? '${salary.workingDays.toStringAsFixed(0)} lectures'
                                  : 'Absents: ${salary.absents.toStringAsFixed(1)} days',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (hasAdvance || isOverpaid) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (hasAdvance) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Advance: Rs ${NumberFormat.compact().format(salary.advanceAmount)}',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (isOverpaid) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Overpaid: Rs ${NumberFormat.compact().format(salary.paidAmount - salary.totalSalary)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildCardStat(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 3 / 4,
      size.height - 40,
      size.width,
      size.height - 10,
    );
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
