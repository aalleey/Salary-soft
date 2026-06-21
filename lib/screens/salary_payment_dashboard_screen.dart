import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../models/salary.dart';
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
  String? _selectedCampus;
  String _searchQuery = '';
  String _filterStatus = 'All'; // All, Paid, Partial Paid, Pending
  
  bool _isSuperAdmin = false;
  String? _userCampus;
  List<String> _campusNames = ['All Campuses'];

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
    final user = authProvider.currentUser;
    _userCampus = authProvider.activeCampus;
    _isSuperAdmin = _userCampus == null || _userCampus!.isEmpty;

    if (_isSuperAdmin) {
      try {
        final campuses = await _firebaseService.getCampuses();
        if (mounted) {
          setState(() {
            _campusNames = ['All Campuses', ...campuses.map((c) => c.name)];
            _selectedCampus = 'All Campuses';
          });
        }
      } catch (e) {
        // error
      }
    } else {
      _selectedCampus = _userCampus;
    }
  }

  String? get _effectiveCampus {
    if (!_isSuperAdmin) return _userCampus;
    if (_selectedCampus == 'All Campuses') return null;
    return _selectedCampus;
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
          children: _campusNames
              .map(
                (campus) => ListTile(
                  title: Text(campus),
                  trailing: _selectedCampus == campus
                      ? const Icon(Icons.check, color: Colors.deepPurple)
                      : null,
                  onTap: () {
                    setState(() => _selectedCampus = campus);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Salary Payments'),
        actions: [
           IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recalculate All',
            onPressed: _handleRecalculate,
           )
        ]
      ),
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
                                label: _selectedCampus ?? 'All Campuses',
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
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final salary = filteredSalaries[index];
                        final hasAdvance = salary.advanceAmount > 0;
                        final isOverpaid = salary.paidAmount > salary.totalSalary;
                        final hasSpecialStatus = hasAdvance || isOverpaid;
                        final avatarColor = hasSpecialStatus ? Colors.purple : salary.statusColor;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: avatarColor.withValues(alpha: 0.2),
                                child: Icon(Icons.person, color: avatarColor),
                              ),
                              title: Text(salary.staffName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Net: ${salary.formattedTotalSalary}', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('Paid: Rs ${NumberFormat('#,##0').format(salary.paidAmount)}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                                    if (hasAdvance) ...[
                                      const SizedBox(height: 4),
                                      Text('Advance: Rs ${NumberFormat('#,##0').format(salary.advanceAmount)}', style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                    if (isOverpaid) ...[
                                      const SizedBox(height: 4),
                                      Text('Overpaid: Rs ${NumberFormat('#,##0').format(salary.paidAmount - salary.totalSalary)}', style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: salary.statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      salary.statusText,
                                      style: TextStyle(color: salary.statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                ],
                              ),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => SalaryPaymentBottomSheet(salary: salary),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      childCount: filteredSalaries.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
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
