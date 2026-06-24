import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/staff.dart';
import '../providers/auth_provider.dart';

class DeletedStaffScreen extends StatefulWidget {
  const DeletedStaffScreen({super.key});

  @override
  State<DeletedStaffScreen> createState() => _DeletedStaffScreenState();
}

class _DeletedStaffScreenState extends State<DeletedStaffScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Staff> _deletedStaff = [];
  bool _isLoading = true;

  Map<String, String> _campusMap = {};

  @override
  void initState() {
    super.initState();
    _loadDeletedStaff();
  }

  Future<void> _loadDeletedStaff() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final campus = authProvider.activeCampus;

      final campuses = await _firebaseService.getCampuses();
      final staff = await _firebaseService.getDeletedStaff(campus: campus);
      if (mounted) {
        setState(() {
          _campusMap = {for (var c in campuses) c.id: c.name};
          _deletedStaff = staff;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading deleted staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreStaff(Staff staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Staff'),
        content: Text(
          'Are you sure you want to restore "${staff.name}"?\n\nThey will appear in the active staff list again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firebaseService.restoreStaff(staff.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${staff.name} restored successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDeletedStaff(); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error restoring staff: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Staff'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedStaff.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No deleted staff',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All staff members are active',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _deletedStaff.length,
              itemBuilder: (context, index) {
                final staff = _deletedStaff[index];
                return _buildStaffCard(staff, isDark);
              },
            ),
    );
  }

  Widget _buildStaffCard(Staff staff, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Text(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Staff Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _campusMap[staff.campus] ?? staff.campus,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  Text(
                    staff.salaryType == 'Hourly'
                        ? 'Salary: Rs ${staff.hourlyRate.toStringAsFixed(0)}/hr'
                        : staff.salaryType == 'Lecture'
                            ? 'Salary: Rs ${staff.salary.toStringAsFixed(0)}/lec'
                            : 'Salary: Rs ${staff.salary.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Restore Button
            ElevatedButton.icon(
              onPressed: () => _restoreStaff(staff),
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Restore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
