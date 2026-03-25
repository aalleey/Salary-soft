import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../models/attendance.dart';
import '../models/campus.dart';
import '../models/staff.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedCampus = 'All';

  List<Attendance> _attendanceList = [];
  List<Staff> _allStaff = [];
  List<Campus> _campuses = [];
  bool _isLoading = true;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final userCampus = user?.campus;
    _isSuperAdmin = userCampus == null || userCampus.isEmpty;

    if (!_isSuperAdmin && userCampus != null) {
      _selectedCampus = userCampus;
    }

    await Future.wait([_loadCampuses(), _loadStaff()]);
    await _loadAttendance();
  }

  Future<void> _loadCampuses() async {
    try {
      final campuses = await _firebaseService.getCampuses();
      if (mounted) {
        setState(() => _campuses = campuses);
      }
    } catch (e) {
      // Ignore campus loading errors
    }
  }

  Future<void> _loadStaff() async {
    try {
      final staff = await _firebaseService.getAllStaff();
      if (mounted) {
        setState(() => _allStaff = staff);
      }
    } catch (e) {
      // Ignore staff loading errors
    }
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);

    try {
      final attendance = await _firebaseService.getAttendance(
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (mounted) {
        setState(() {
          _attendanceList = attendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<_StaffAttendanceData> _getFilteredAttendanceData() {
    // Get staff filtered by campus
    List<Staff> filteredStaff = _allStaff;
    if (_selectedCampus != 'All') {
      filteredStaff = _allStaff
          .where((s) => s.campus == _selectedCampus)
          .toList();
    }

    // Create attendance data for each staff member
    return filteredStaff.map((staff) {
      // Find attendance record for this staff in selected month/year
      final attendance = _attendanceList.firstWhere(
        (a) => a.staffId == staff.id,
        orElse: () => Attendance(
          id: '',
          staffId: staff.id,
          staffName: staff.name,
          month: _selectedMonth,
          year: _selectedYear,
          absents: 0,
          lates: 0,
          halfLeaves: 0,
        ),
      );

      return _StaffAttendanceData(staff: staff, attendance: attendance);
    }).toList()..sort((a, b) => a.staff.name.compareTo(b.staff.name));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredData = _getFilteredAttendanceData();

    // Calculate totals
    int totalAbsents = 0;
    int totalLates = 0;
    int totalHalfLeaves = 0;
    for (var data in filteredData) {
      totalAbsents += data.attendance.absents;
      totalLates += data.attendance.lates;
      totalHalfLeaves += data.attendance.halfLeaves;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Attendance Report',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.teal.shade700, Colors.cyan.shade500],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month/Year Selector
                  _buildMonthYearSelector(isDark),
                  const SizedBox(height: 16),

                  // Campus Filter (for super admins)
                  if (_isSuperAdmin) ...[
                    _buildCampusFilter(isDark),
                    const SizedBox(height: 16),
                  ],

                  // Summary Cards
                  _buildSummaryCards(
                    filteredData.length,
                    totalAbsents,
                    totalLates,
                    totalHalfLeaves,
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Text(
                    'Staff Attendance Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Attendance List
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredData.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No staff found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildAttendanceCard(filteredData[index], isDark),
                  childCount: filteredData.length,
                ),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildMonthYearSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedMonth,
              decoration: InputDecoration(
                labelText: 'Month',
                prefixIcon: const Icon(Icons.calendar_month),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: List.generate(12, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text(
                    DateFormat.MMMM().format(DateTime(2024, index + 1)),
                  ),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMonth = value);
                  _loadAttendance();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: InputDecoration(
                labelText: 'Year',
                prefixIcon: const Icon(Icons.date_range),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: List.generate(5, (index) {
                final year = DateTime.now().year - 2 + index;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedYear = value);
                  _loadAttendance();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCampusChip('All', isDark),
            ..._campuses.map((c) => _buildCampusChip(c.name, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusChip(String campus, bool isDark) {
    final isSelected = _selectedCampus == campus;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(campus),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCampus = campus);
        },
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        selectedColor: Colors.teal.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.teal.shade700 : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    int staffCount,
    int absents,
    int lates,
    int halfLeaves,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Staff',
            staffCount.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Absents',
            absents.toString(),
            Icons.event_busy,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Lates',
            lates.toString(),
            Icons.access_time,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Half',
            halfLeaves.toString(),
            Icons.timelapse,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(180), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(_StaffAttendanceData data, bool isDark) {
    final staff = data.staff;
    final attendance = data.attendance;
    final hasAttendance =
        attendance.absents > 0 ||
        attendance.lates > 0 ||
        attendance.halfLeaves > 0;
    final hasRecord = attendance.id.isNotEmpty; // Check if record exists in DB

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Staff Avatar
            CircleAvatar(
              backgroundColor: hasAttendance
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              child: Text(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: hasAttendance
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Staff Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    staff.campus,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Attendance Stats
            _buildStatBadge('A', attendance.absents, Colors.red),
            const SizedBox(width: 8),
            _buildStatBadge('L', attendance.lates, Colors.orange),
            const SizedBox(width: 8),
            _buildStatBadge('H', attendance.halfLeaves, Colors.amber),

            // Delete button (only for super admins and if record exists)
            if (_isSuperAdmin && hasRecord) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade400,
                  size: 22,
                ),
                onPressed: () => _confirmDeleteAttendance(data),
                tooltip: 'Delete Attendance',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAttendance(_StaffAttendanceData data) async {
    final monthName = DateFormat.MMMM().format(DateTime(2024, _selectedMonth));

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance'),
        content: Text(
          'Are you sure you want to delete attendance for "${data.staff.name}" for $monthName $_selectedYear?\n\nThis will also recalculate their salary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.deleteAttendance(
          data.attendance.id,
          data.attendance.staffId,
          _selectedMonth,
          _selectedYear,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAttendance(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting attendance: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    final hasValue = value > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasValue ? color.withAlpha(38) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: hasValue ? color : Colors.grey.shade400,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: hasValue ? color : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffAttendanceData {
  final Staff staff;
  final Attendance attendance;

  _StaffAttendanceData({required this.staff, required this.attendance});
}
