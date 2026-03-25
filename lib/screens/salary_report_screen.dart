import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../models/salary.dart';
import '../widgets/celebration_overlay.dart';

class SalaryReportScreen extends StatefulWidget {
  const SalaryReportScreen({super.key});

  @override
  State<SalaryReportScreen> createState() => _SalaryReportScreenState();
}

class _SalaryReportScreenState extends State<SalaryReportScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final PdfService _pdfService = PdfService();
  final TextEditingController _searchController = TextEditingController();

  // Filter state
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String? _selectedCampus;
  String _searchQuery = '';
  String _filterStatus = 'All'; // All, Paid, Unpaid

  // Selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedSalaryIds = {};

  // Data state
  List<String> _campusNames = ['All Campuses'];
  bool _isSuperAdmin = false;
  String? _userCampus;
  bool _showCelebration = false;

  // Animation

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _initializeData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    _userCampus = user?.campus;
    _isSuperAdmin = _userCampus == null || _userCampus!.isEmpty;

    if (_isSuperAdmin) {
      await _loadCampuses();
    } else {
      _selectedCampus = _userCampus;
    }

    await _loadActiveStaff();
    if (mounted) _animController.forward();
  }

  Future<void> _loadCampuses() async {
    try {
      final campuses = await _firebaseService.getCampuses();
      if (mounted) {
        setState(() {
          _campusNames = ['All Campuses', ...campuses.map((c) => c.name)];
          _selectedCampus = 'All Campuses';
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadActiveStaff() async {
    // Intentionally left empty or removed if strictly unused.
    // However, keeping the method structure if needed later, but removing unused logic.
  }

  String? get _effectiveCampus {
    if (!_isSuperAdmin) return _userCampus;
    if (_selectedCampus == 'All Campuses') return null;
    return _selectedCampus;
  }

  List<Salary> _filterSalaries(List<Salary> salaries) {
    return salaries.where((s) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        if (!s.staffName.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Status filter
      if (_filterStatus == 'Paid' && !s.isPaid) return false;
      if (_filterStatus == 'Unpaid' && s.isPaid) return false;

      return true;
    }).toList()..sort((a, b) => a.staffName.compareTo(b.staffName));
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedSalaryIds.clear();
    });
  }

  void _toggleSalarySelection(String id) {
    setState(() {
      if (_selectedSalaryIds.contains(id)) {
        _selectedSalaryIds.remove(id);
      } else {
        _selectedSalaryIds.add(id);
      }
    });
  }

  Future<void> _batchMarkAsPaid() async {
    if (_selectedSalaryIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Mark ${_selectedSalaryIds.length} salaries as PAID?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firebaseService.batchMarkSalariesAsPaid(
        _selectedSalaryIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedSalaryIds.length} salaries updated'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isSelectionMode = false;
          _selectedSalaryIds.clear();
          _showCelebration = true;
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

  Future<void> _handleRecalculate() async {
    // Show confirmation dialog before recalculating
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
      const SnackBar(
        content: Text('Recalculating...'),
        duration: Duration(seconds: 2),
      ),
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
            behavior: SnackBarBehavior.floating,
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

  Future<void> _exportPdf(List<Salary> salaries) async {
    try {
      final pdfBytes = await _pdfService.generateMonthlyReport(
        salaries,
        _selectedMonth,
        _selectedYear,
        _effectiveCampus,
      );
      await Printing.layoutPdf(onLayout: (format) => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffold = Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, isDark),
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

          // Calculate summary stats
          final totalPayable = allSalaries.fold<double>(
            0,
            (sum, s) => sum + s.totalSalary,
          );
          final totalPaid = allSalaries
              .where((s) => s.isPaid)
              .fold<double>(0, (sum, s) => sum + s.totalSalary);

          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 80,
                ),
              ),
              // Summary Cards Header
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildSummaryHeader(totalPayable, totalPaid, isDark),
                        const SizedBox(height: 24),
                        _buildFilterBar(isDark),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              // Salary List
              if (filteredSalaries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 64,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No records found',
                          style: TextStyle(
                            color: theme.disabledColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final salary = filteredSalaries[index];
                    return _buildSalaryCard(salary, index, isDark);
                  }, childCount: filteredSalaries.length),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActions(filteredSalaries: []),
    );

    return CelebrationOverlay(
      isPlaying: _showCelebration,
      onFinished: () => setState(() => _showCelebration = false),
      child: scaffold,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Salary Report',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: false,
      flexibleSpace: ClipPath(
        clipper: _HeaderClipper(),
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
        ),
      ),
      actions: [
        if (_isSelectionMode)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleSelectionMode,
          )
        else
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'select') _toggleSelectionMode();
              if (value == 'recalculate') await _handleRecalculate();
              if (value == 'pdf') {
                // Fetch current filtered salaries to export - tricky in stream builder
                // For simplicity export what's in the query
                final salaries = await _firebaseService.getSalaries(
                  month: _selectedMonth,
                  year: _selectedYear,
                  campus: _effectiveCampus,
                );
                _exportPdf(salaries);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'select',
                child: Row(
                  children: [
                    Icon(Icons.checklist, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Select Multiple'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'recalculate',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Recalculate All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSummaryHeader(
    double totalPayable,
    double totalPaid,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryStat(
                'Total Payable',
                'Rs ${NumberFormat.compact().format(totalPayable)}',
                Colors.deepPurple,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              _buildSummaryStat(
                'Paid',
                'Rs ${NumberFormat.compact().format(totalPaid)}',
                Colors.green,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              _buildSummaryStat(
                'Pending',
                'Rs ${NumberFormat.compact().format(totalPayable - totalPaid)}',
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalPayable > 0 ? totalPaid / totalPayable : 0,
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(Colors.green),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Month Selector
          _buildFilterChip(
            label: DateFormat(
              'MMMM',
            ).format(DateTime(_selectedYear, _selectedMonth)),
            icon: Icons.calendar_month,
            isDark: isDark,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(_selectedYear, _selectedMonth),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDatePickerMode:
                    DatePickerMode.year, // Simplified roughly
              );
              if (date != null) {
                setState(() {
                  _selectedYear = date.year;
                  _selectedMonth = date.month;
                });
              }
            },
          ),
          const SizedBox(width: 12),
          // Campus Selector (Super Admin)
          if (_isSuperAdmin) ...[
            _buildFilterChip(
              label: _selectedCampus ?? 'All Campuses',
              icon: Icons.business,
              isDark: isDark,
              onTap: _showCampusSelector,
            ),
            const SizedBox(width: 12),
          ],
          // Status Selector
          _buildFilterChip(
            label: _filterStatus,
            icon: Icons.filter_list,
            isDark: isDark,
            onTap: () {
              setState(() {
                if (_filterStatus == 'All') {
                  _filterStatus = 'Paid';
                } else if (_filterStatus == 'Paid') {
                  _filterStatus = 'Unpaid';
                } else {
                  _filterStatus = 'All';
                }
              });
            },
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
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
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildSalaryCard(Salary salary, int index, bool isDark) {
    final isSelected = _selectedSalaryIds.contains(salary.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: _isSelectionMode && isSelected
            ? Border.all(color: Colors.deepPurple, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _isSelectionMode
              ? () => _toggleSalarySelection(salary.id)
              : () => _showPayAdvanceDialog(salary),
          onLongPress: _toggleSelectionMode,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade50,
                      child: Text(
                        salary.staffName.isNotEmpty
                            ? salary.staffName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.deepPurple,
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
                            salary.campus ?? 'Unknown Campus',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(salary.isPaid),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCardStat(
                      'Basic',
                      'Rs ${NumberFormat.compact().format(salary.basicSalary)}',
                    ),
                    _buildCardStat(
                      'Deductions',
                      'Rs ${NumberFormat.compact().format(salary.deduction)}',
                      color: Colors.red,
                    ),
                    _buildCardStat(
                      'Net Salary',
                      'Rs ${NumberFormat.compact().format(salary.totalSalary)}',
                      color: Colors.green,
                      isBold: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPaid
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPaid ? 'PAID' : 'PENDING',
        style: TextStyle(
          color: isPaid ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 10,
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
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
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

  Widget? _buildFloatingActions({required List<Salary> filteredSalaries}) {
    if (_isSelectionMode && _selectedSalaryIds.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: _batchMarkAsPaid,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.check),
        label: Text('Mark (${_selectedSalaryIds.length}) Paid'),
      );
    }
    return null;
  }

  void _showPayAdvanceDialog(Salary salary) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                salary.staffName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModalAction(
                    icon: Icons.print_rounded,
                    label: 'Print Slip',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _printSalarySlip(salary);
                    },
                  ),
                  if (!salary.isPaid)
                    _buildModalAction(
                      icon: Icons.check_circle_rounded,
                      label: 'Mark Paid',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _toggleSalaryPaid(salary);
                      },
                    )
                  else
                    _buildModalAction(
                      icon: Icons.undo_rounded,
                      label: 'Mark Unpaid',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _toggleSalaryPaid(salary);
                      },
                    ),
                  _buildModalAction(
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteSalary(salary);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSalaryPaid(Salary salary) async {
    try {
      await _firebaseService.toggleSalaryPaidStatus(salary.id, !salary.isPaid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              salary.isPaid ? 'Marked as Unpaid' : 'Marked as Paid',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: salary.isPaid ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _printSalarySlip(Salary salary) async {
    final pdfBytes = await _pdfService.generatePayslip(salary);
    await Printing.layoutPdf(onLayout: (format) => pdfBytes);
  }

  Future<void> _deleteSalary(Salary salary) async {
    await _firebaseService.deleteSalary(salary.id);
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height,
    );
    path.quadraticBezierTo(
      size.width - (size.width / 4),
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
