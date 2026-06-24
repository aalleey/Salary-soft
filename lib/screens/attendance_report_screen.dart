import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../models/attendance.dart';
import '../models/campus.dart';
import '../models/staff.dart';
import '../shared/widgets/glass_card_widget.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final PdfService _pdfService = PdfService();

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedCampusId = 'All';
  Map<String, String> _campusMap = {};

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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userCampus = auth.activeCampus;
    _isSuperAdmin = userCampus == null || userCampus.isEmpty;

    if (!_isSuperAdmin && userCampus != null) {
      _selectedCampusId = userCampus;
    }

    await Future.wait([_loadCampuses(), _loadStaff()]);
    await _loadAttendance();
  }

  Future<void> _loadCampuses() async {
    try {
      final campuses = await _firebaseService.getCampuses();
      if (mounted) {
        setState(() {
          _campuses = campuses;
          _campusMap = {for (var c in campuses) c.id: c.name};
        });
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

  Future<void> _exportPdf(List<_StaffAttendanceData> data) async {
    try {
      final campusName = _selectedCampusId == 'All'
          ? 'All Campuses'
          : (_campusMap[_selectedCampusId] ?? _selectedCampusId);
          
      final pdfDataList = data.map((d) {
        final resolvedCampus = _campusMap[d.staff.campus] ?? d.staff.campus;
        return AttendanceReportData(
          staffName: d.staff.name,
          campusName: resolvedCampus,
          salaryType: d.staff.salaryType,
          absents: d.attendance.absents,
          lates: d.attendance.lates,
          halfLeaves: d.attendance.halfLeaves,
          totalHours: d.attendance.totalWorkingHours,
          totalLectures: d.attendance.totalLectures,
        );
      }).toList();

      final pdfBytes = await _pdfService.generateAttendanceReport(
        pdfDataList,
        _selectedMonth,
        _selectedYear,
        campusName,
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

  List<_StaffAttendanceData> _getFilteredAttendanceData() {
    // Get staff filtered by campus
    List<Staff> filteredStaff = _allStaff;
    if (_selectedCampusId != 'All') {
      filteredStaff = _allStaff
          .where((s) => s.campus == _selectedCampusId)
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
    double totalHours = 0.0;
    double totalLectures = 0.0;
    
    bool hasHourly = false;
    bool hasLecture = false;
    bool hasMonthly = false;

    for (var data in filteredData) {
      if (data.staff.salaryType == 'Hourly') {
        totalHours += data.attendance.totalWorkingHours;
        hasHourly = true;
      } else if (data.staff.salaryType == 'Lecture') {
        totalLectures += data.attendance.totalLectures;
        hasLecture = true;
      } else {
        totalAbsents += data.attendance.absents;
        totalLates += data.attendance.lates;
        totalHalfLeaves += data.attendance.halfLeaves;
        hasMonthly = true;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0F2027),
                        const Color(0xFF203A43),
                        const Color(0xFF2C5364),
                      ]
                    : [
                        const Color(0xFFE0EAFC),
                        const Color(0xFFCFDEF3),
                      ],
              ),
            ),
          ),
          // Glowing orbs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark 
                    ? Colors.tealAccent.withValues(alpha: 0.15)
                    : Colors.tealAccent.withValues(alpha: 0.08),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 140.0,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    onPressed: () => _exportPdf(filteredData),
                    tooltip: 'Export PDF',
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: ClipPath(
                  clipper: _HeaderClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF004d40),
                          Colors.teal.shade700,
                          const Color(0xFF00acc1),
                        ],
                      ),
                    ),
                    child: const Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, bottom: 24),
                        child: Text(
                          'Attendance Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            letterSpacing: -0.5,
                          ),
                        ),
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
                        staffCount: filteredData.length,
                        absents: totalAbsents,
                        lates: totalLates,
                        halfLeaves: totalHalfLeaves,
                        totalHours: totalHours,
                        totalLectures: totalLectures,
                        hasHourly: hasHourly,
                        hasLecture: hasLecture,
                        hasMonthly: hasMonthly,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),

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
              initialValue: _selectedMonth,
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
              initialValue: _selectedYear,
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
            _buildCampusChip('All', 'All', isDark),
            ..._campuses.map((c) => _buildCampusChip(c.id, c.name, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusChip(String campusId, String label, bool isDark) {
    final isSelected = _selectedCampusId == campusId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCampusId = campusId);
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

  Widget _buildSummaryCards({
    required int staffCount,
    required int absents,
    required int lates,
    required int halfLeaves,
    required double totalHours,
    required double totalLectures,
    required bool hasHourly,
    required bool hasLecture,
    required bool hasMonthly,
    required bool isDark,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildSummaryCard(
            'Staff',
            staffCount.toString(),
            Icons.people,
            Colors.blue,
          ),
          if (hasMonthly) ...[
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Absents',
              absents.toString(),
              Icons.event_busy,
              Colors.red,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Lates',
              lates.toString(),
              Icons.access_time,
              Colors.orange,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Half Leaves',
              halfLeaves.toString(),
              Icons.timelapse,
              Colors.amber,
            ),
          ],
          if (hasHourly) ...[
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Hours',
              totalHours.toStringAsFixed(totalHours == totalHours.roundToDouble() ? 0 : 1),
              Icons.access_time_filled_rounded,
              Colors.purple,
            ),
          ],
          if (hasLecture) ...[
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Lectures',
              totalLectures.toStringAsFixed(totalLectures == totalLectures.roundToDouble() ? 0 : 1),
              Icons.school_rounded,
              Colors.teal,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(_StaffAttendanceData data, bool isDark) {
    final staff = data.staff;
    final attendance = data.attendance;
    final hasPerformance = staff.salaryType == 'Hourly'
        ? attendance.totalWorkingHours > 0
        : staff.salaryType == 'Lecture'
            ? attendance.totalLectures > 0
            : (attendance.absents == 0 && attendance.lates == 0 && attendance.halfLeaves == 0);
    final hasRecord = attendance.id.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 16,
        child: Row(
          children: [
            // Staff Avatar
            CircleAvatar(
              backgroundColor: hasPerformance
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              child: Text(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: hasPerformance
                      ? Colors.green
                      : Colors.red,
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
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _campusMap[staff.campus] ?? staff.campus,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Attendance Stats
            if (staff.salaryType == 'Hourly') ...[
              _buildStatBadgeDouble('Hours', attendance.totalWorkingHours, Colors.purple),
            ] else if (staff.salaryType == 'Lecture') ...[
              _buildStatBadgeDouble('Lectures', attendance.totalLectures, Colors.teal),
            ] else ...[
              _buildStatBadge('Absents', attendance.absents, Colors.red),
              const SizedBox(width: 6),
              _buildStatBadge('Lates', attendance.lates, Colors.orange),
              const SizedBox(width: 6),
              _buildStatBadge('Half', attendance.halfLeaves, Colors.amber),
            ],

            // Actions for super admin
            if (_isSuperAdmin) ...[
              const SizedBox(width: 8),
              if (hasRecord)
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.blue,
                    size: 20,
                  ),
                  onPressed: () => _editAttendance(data),
                  tooltip: 'Edit Attendance',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                  onPressed: () => _editAttendance(data),
                  tooltip: 'Add Attendance',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (hasRecord)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
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

  Future<void> _editAttendance(_StaffAttendanceData data) async {
    final staff = data.staff;
    final isHourly = staff.salaryType == 'Hourly';
    final isLecture = staff.salaryType == 'Lecture';

    final absentsController = TextEditingController(text: data.attendance.absents.toString());
    final latesController = TextEditingController(text: data.attendance.lates.toString());
    final halfLeavesController = TextEditingController(text: data.attendance.halfLeaves.toString());
    final workingHoursController = TextEditingController(text: data.attendance.totalWorkingHours.toString());
    final lecturesController = TextEditingController(text: data.attendance.totalLectures.toString());

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit Attendance - ${staff.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHourly) ...[
                TextField(
                  controller: workingHoursController,
                  decoration: InputDecoration(
                    labelText: 'Total Working Hours',
                    prefixIcon: const Icon(Icons.access_time_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ] else if (isLecture) ...[
                TextField(
                  controller: lecturesController,
                  decoration: InputDecoration(
                    labelText: 'Lectures Conducted',
                    prefixIcon: const Icon(Icons.school_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ] else ...[
                TextField(
                  controller: absentsController,
                  decoration: InputDecoration(
                    labelText: 'Full Day Absents',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: latesController,
                  decoration: InputDecoration(
                    labelText: 'Late Arrivals',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: halfLeavesController,
                  decoration: InputDecoration(
                    labelText: 'Half Leaves',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final double totalWorkingHours = double.tryParse(workingHoursController.text) ?? 0.0;
      final double totalLectures = double.tryParse(lecturesController.text) ?? 0.0;
      final absents = int.tryParse(absentsController.text) ?? 0;
      final lates = int.tryParse(latesController.text) ?? 0;
      final halfLeaves = int.tryParse(halfLeavesController.text) ?? 0;

      final updatedAttendance = Attendance(
        id: data.attendance.id,
        staffId: data.staff.id,
        staffName: data.staff.name,
        month: _selectedMonth,
        year: _selectedYear,
        absents: isHourly || isLecture ? 0 : absents,
        lates: isHourly || isLecture ? 0 : lates,
        halfLeaves: isHourly || isLecture ? 0 : halfLeaves,
        totalWorkingHours: isHourly ? totalWorkingHours : 0.0,
        totalLectures: isLecture ? totalLectures : 0.0,
      );

      try {
        if (data.attendance.id.isNotEmpty) {
          await _firebaseService.updateAttendance(data.attendance.id, updatedAttendance);
        } else {
          await _firebaseService.addAttendance(updatedAttendance);
        }
        
        // Recalculate salary
        await _firebaseService.recalculateAndSaveSalary(data.staff.id, _selectedMonth, _selectedYear);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance saved & salary recalculated!'), backgroundColor: Colors.green),
          );
          _loadAttendance(); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving attendance: $e'), backgroundColor: Colors.red),
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
        color: hasValue ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
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

  Widget _buildStatBadgeDouble(String label, double value, Color color) {
    final hasValue = value > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasValue ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
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

class _HeaderClipper extends CustomClipper<Path> {
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
