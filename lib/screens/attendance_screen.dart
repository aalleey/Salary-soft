import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/staff.dart';
import '../models/attendance.dart';
import '../models/campus.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _absentsController = TextEditingController();
  final _latesController = TextEditingController();
  final _halfLeavesController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _lecturesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Staff> _staffList = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  Staff? _selectedStaff;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // Campus filter
  List<Campus> _campuses = [];
  Map<String, String> _campusMap = {};
  String _selectedCampusId = 'All';
  bool _isLoadingCampuses = false;

  // Filtered staff based on campus selection
  List<Staff> get _filteredStaffList {
    if (_selectedCampusId == 'All') {
      return _staffList;
    }
    return _staffList.where((s) => s.campus == _selectedCampusId).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCampuses();
    _loadStaff();
  }

  Future<void> _loadExistingAttendanceForSelected() async {
    if (_selectedStaff == null) return;
    try {
      final records = await _firebaseService.getAttendance(
        month: _selectedMonth,
        year: _selectedYear,
        staffId: _selectedStaff!.id,
      );
      final summaries = records.where((r) => r.date == null).toList();
      if (summaries.isNotEmpty) {
        final summary = summaries.first;
        setState(() {
          _absentsController.text = summary.absents.toString();
          _latesController.text = summary.lates.toString();
          _halfLeavesController.text = summary.halfLeaves.toString();
          _workingHoursController.text = summary.totalWorkingHours > 0 
              ? summary.totalWorkingHours.toStringAsFixed(1) 
              : '';
          _lecturesController.text = summary.totalLectures > 0 
              ? summary.totalLectures.toStringAsFixed(0) 
              : '';
        });
      } else {
        setState(() {
          _absentsController.clear();
          _latesController.clear();
          _halfLeavesController.clear();
          _workingHoursController.clear();
          _lecturesController.clear();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCampuses() async {
    setState(() => _isLoadingCampuses = true);
    try {
      final campuses = await _firebaseService.getCampuses();
      if (mounted) {
        setState(() {
          _campuses = campuses;
          _campusMap = {for (var c in campuses) c.id: c.name};
          _isLoadingCampuses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCampuses = false);
    }
  }

  @override
  void dispose() {
    _absentsController.dispose();
    _latesController.dispose();
    _halfLeavesController.dispose();
    _workingHoursController.dispose();
    _lecturesController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final staff = await _firebaseService.getAllStaff(
        campus: authProvider.activeCampus,
      );
      if (mounted) {
        setState(() {
          _staffList = staff;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading staff: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a staff member'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      double workingHours = 0.0;
      double totalLectures = 0.0;
      int absents = 0;
      int lates = 0;
      int halfLeaves = 0;

      if (_selectedStaff!.salaryType == 'Hourly') {
        workingHours = double.tryParse(_workingHoursController.text) ?? 0.0;
      } else if (_selectedStaff!.salaryType == 'Lecture') {
        totalLectures = double.tryParse(_lecturesController.text) ?? 0.0;
      } else {
        absents = int.parse(_absentsController.text);
        lates = _latesController.text.isEmpty
            ? 0
            : int.parse(_latesController.text);
        halfLeaves = _halfLeavesController.text.isEmpty
            ? 0
            : int.parse(_halfLeavesController.text);
      }

      // Check for existing attendance record (monthly summary has date == null)
      final existingAttendanceList = await _firebaseService.getAttendance(
        month: _selectedMonth,
        year: _selectedYear,
        staffId: _selectedStaff!.id,
      );
      final existingSummaries = existingAttendanceList.where((a) => a.date == null).toList();

      final attendance = Attendance(
        id: existingSummaries.isNotEmpty ? existingSummaries.first.id : '',
        staffId: _selectedStaff!.id,
        staffName: _selectedStaff!.name,
        month: _selectedMonth,
        year: _selectedYear,
        absents: absents,
        lates: lates,
        halfLeaves: halfLeaves,
        totalWorkingHours: workingHours,
        totalLectures: totalLectures,
      );

      if (existingSummaries.isNotEmpty) {
        await _firebaseService.updateAttendance(attendance.id, attendance);
      } else {
        await _firebaseService.addAttendance(attendance);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance ${existingSummaries.isNotEmpty ? 'updated' : 'recorded'} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Reset form fields but keep month/year
        _formKey.currentState!.reset();
        setState(() {
          _selectedStaff = null;
          _absentsController.clear();
          _latesController.clear();
          _halfLeavesController.clear();
          _workingHoursController.clear();
          _lecturesController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Mark Attendance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo.shade700, Colors.purple.shade500],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMonthYearSelector(),
                  const SizedBox(height: 16),
                  _buildCampusFilterChips(),
                  const SizedBox(height: 16),
                  _buildFormCard(),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthYearSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.date_range, color: Colors.indigo),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Period',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  value: _selectedMonth,
                  label: 'Month',
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(
                        _monthNames[index],
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMonth = value);
                      _loadExistingAttendanceForSelected();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  value: _selectedYear,
                  label: 'Year',
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
                      _loadExistingAttendanceForSelected();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampusFilterChips() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userCampus = authProvider.activeCampus;
    final isSuperAdmin = userCampus == null || userCampus.isEmpty;

    // Only show filter for super admins
    if (!isSuperAdmin || _isLoadingCampuses) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Filter by Campus',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                selected: _selectedCampusId == 'All',
                label: const Text('All'),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCampusId = 'All';
                    });
                  }
                },
                selectedColor: Colors.teal.shade100,
                backgroundColor: Colors.grey.shade100,
                checkmarkColor: Colors.teal.shade700,
                labelStyle: TextStyle(
                  color: _selectedCampusId == 'All'
                      ? Colors.teal.shade800
                      : Colors.grey.shade700,
                  fontWeight: _selectedCampusId == 'All' ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              ..._campuses.map((campus) {
                final isSelected = _selectedCampusId == campus.id;
                return FilterChip(
                  selected: isSelected,
                  label: Text(campus.name),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCampusId = campus.id;
                        // Reset selected staff when campus changes
                        if (_selectedStaff != null && _selectedStaff!.campus != campus.id) {
                          _selectedStaff = null;
                        }
                      });
                    } else {
                      setState(() {
                        _selectedCampusId = 'All';
                      });
                    }
                  },
                  selectedColor: Colors.teal.shade100,
                  backgroundColor: Colors.grey.shade100,
                  checkmarkColor: Colors.teal.shade700,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.teal.shade800
                        : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required int value,
    required String label,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Widget _buildFormCard() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Attendance Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Staff Dropdown
            DropdownButtonFormField<Staff>(
              initialValue: _selectedStaff,
              decoration: _buildInputDecoration(
                label: 'Select Staff *',
                icon: Icons.person_outline,
                iconColor: Colors.indigo,
              ),
              isExpanded: true,
              items: _filteredStaffList.map((staff) {
                final campusName = _campusMap[staff.campus] ?? staff.campus;
                return DropdownMenuItem(
                  value: staff,
                  child: Text(
                    '${staff.name} ($campusName)',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedStaff = value);
                _loadExistingAttendanceForSelected();
              },
              validator: (value) =>
                  value == null ? 'Please select a staff member' : null,
            ),
            const SizedBox(height: 20),

            if (_selectedStaff == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'Please select a staff member above to enter attendance metrics.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            else if (_selectedStaff!.salaryType == 'Hourly') ...[
              // Working Hours Field
              TextFormField(
                controller: _workingHoursController,
                decoration: _buildInputDecoration(
                  label: 'Total Working Hours *',
                  icon: Icons.timer_outlined,
                  iconColor: Colors.blue,
                  hint: 'Enter total working hours for the month',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter working hours';
                  }
                  final hours = double.tryParse(value);
                  if (hours == null || hours < 0) {
                    return 'Enter a valid number of hours';
                  }
                  return null;
                },
              ),
            ] else if (_selectedStaff!.salaryType == 'Lecture') ...[
              // Lectures Conducted Field
              TextFormField(
                controller: _lecturesController,
                decoration: _buildInputDecoration(
                  label: 'Total Lectures Conducted *',
                  icon: Icons.school_outlined,
                  iconColor: Colors.purple,
                  hint: 'Enter number of lectures conducted',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter lecture count';
                  }
                  final lecs = double.tryParse(value);
                  if (lecs == null || lecs < 0) {
                    return 'Enter a valid lecture count';
                  }
                  return null;
                },
              ),
            ] else ...[
              // Monthly (absents, lates, half leaves)
              TextFormField(
                controller: _absentsController,
                decoration: _buildInputDecoration(
                  label: 'Full Day Absents *',
                  icon: Icons.event_busy_outlined,
                  iconColor: Colors.red,
                  hint: 'Enter full absent days (0-31)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter number of absents';
                  }
                  final absents = int.tryParse(value);
                  if (absents == null || absents < 0 || absents > 31) {
                    return 'Enter a valid number (0-31)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _halfLeavesController,
                decoration: _buildInputDecoration(
                  label: 'Half Day Leaves',
                  icon: Icons.timelapse_outlined,
                  iconColor: Colors.orange,
                  hint: 'Enter half-day leaves (0-62)',
                  helper: '2 half-leaves = 1 absent deduction',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final halfLeaves = int.tryParse(value);
                    if (halfLeaves == null || halfLeaves < 0 || halfLeaves > 62) {
                      return 'Enter a valid number (0-62)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _latesController,
                decoration: _buildInputDecoration(
                  label: 'Late Arrivals',
                  icon: Icons.schedule,
                  iconColor: Colors.amber.shade700,
                  hint: 'Enter late arrivals (0-31)',
                  helper: '3 lates = 1 absent deduction',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final lates = int.tryParse(value);
                    if (lates == null || lates < 0 || lates > 31) {
                      return 'Enter a valid number (0-31)';
                    }
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text(
                            'Record Attendance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    required Color iconColor,
    String? hint,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperStyle: TextStyle(
        color: iconColor.withValues(alpha: 0.8),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: iconColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: iconColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildInfoCard() {
    final type = _selectedStaff?.salaryType ?? 'Monthly';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.indigo.shade700),
              const SizedBox(width: 8),
              Text(
                'Calculation Rules ($type)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (type == 'Hourly') ...[
            _buildRuleItem(
              icon: Icons.timer,
              color: Colors.blue,
              text: 'Final Salary = workingHours × hourlyRate',
            ),
            _buildRuleItem(
              icon: Icons.history_toggle_off,
              color: Colors.teal,
              text: 'Summed from daily check-ins if not manually overridden',
            ),
            _buildRuleItem(
              icon: Icons.monetization_on_outlined,
              color: Colors.green,
              text: 'Hourly rate is configured per staff member profile',
            ),
          ] else if (type == 'Lecture') ...[
            _buildRuleItem(
              icon: Icons.school,
              color: Colors.purple,
              text: 'Final Salary = totalLectures × lectureRate',
            ),
            _buildRuleItem(
              icon: Icons.monetization_on_outlined,
              color: Colors.green,
              text: 'Rate per lecture is configured as basic salary in staff profile',
            ),
          ] else ...[
            _buildRuleItem(
              icon: Icons.event_busy,
              color: Colors.red,
              text: 'Full Absent = 1 day deduction',
            ),
            _buildRuleItem(
              icon: Icons.timelapse,
              color: Colors.orange,
              text: '2 Half Leaves = 1 day deduction',
            ),
            _buildRuleItem(
              icon: Icons.schedule,
              color: Colors.amber.shade700,
              text: '3 Late Arrivals = 1 day deduction',
            ),
            _buildRuleItem(
              icon: Icons.calculate,
              color: Colors.indigo,
              text: 'Per day = Salary ÷ 30',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
