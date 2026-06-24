import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/staff.dart';
import '../models/campus.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import 'add_edit_staff_screen.dart';
import 'deleted_staff_screen.dart';
import 'staff_profile_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  // Master list contains ALL staff (unfiltered)
  List<Staff> _allStaff = [];
  // Filtered list is what we display
  List<Staff> _filteredStaff = [];

  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  // Campus Filter State
  List<Campus> _campuses = [];
  Map<String, String> _campusMap = {};
  String _selectedCampusId = 'All';
  bool _isLoadingCampuses = false;

  @override
  void initState() {
    super.initState();
    _loadCampuses();
    _loadStaff();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      // Check if user has a specific campus (not null AND not empty)
      final activeCampus = authProvider.activeCampus;
      final userHasCampus = activeCampus != null && activeCampus.isNotEmpty;

      if (userHasCampus) {
        // Campus admin: only show their active campus
        _filteredStaff = _allStaff
            .where((s) => s.campus == activeCampus)
            .toList();
      } else if (_selectedCampusId == 'All') {
        // Super admin with 'All' selected
        _filteredStaff = List.from(_allStaff);
      } else {
        // Super admin with specific campus selected
        _filteredStaff = _allStaff
            .where((s) => s.campus == _selectedCampusId)
            .toList();
      }
    });
  }

  Future<void> _loadStaff({bool isRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      if (isRefresh) {
        _allStaff = [];
        _filteredStaff = [];
      }
    });

    try {
      // Always fetch ALL staff (no campus filter at DB level)
      // This avoids composite index issues
      final allStaff = await _firebaseService.getAllStaff();

      if (mounted) {
        setState(() {
          _allStaff = allStaff;
          _isLoading = false;
        });
        _applyFilter();
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadStaff(isRefresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Staff Directory',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                // Deleted Staff Button
                if (authProvider.hasPermission('view_staff'))
                  IconButton(
                    icon: const Icon(
                      Icons.restore_from_trash,
                      color: Colors.white,
                    ),
                    tooltip: 'View Deleted Staff',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeletedStaffScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadStaff(isRefresh: true);
                      }
                    },
                  ),
                // Add Staff Button
                if (authProvider.hasPermission('add_staff'))
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddEditStaffScreen(),
                        ),
                      );
                      if (result == true) {
                        _loadStaff(isRefresh: true);
                      }
                    },
                  ),
              ],
            ),

            // Campus Filter Chips (show for super admins - activeCampus is null)
            if (authProvider.activeCampus == null && !_isLoadingCampuses)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: _selectedCampusId == 'All',
                          label: const Text('All'),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCampusId = 'All');
                              _applyFilter();
                            }
                          },
                          selectedColor: Colors.indigo.shade100,
                          backgroundColor: Colors.grey.shade200,
                          checkmarkColor: Colors.indigo.shade700,
                          labelStyle: TextStyle(
                            color: _selectedCampusId == 'All'
                                ? Colors.indigo.shade800
                                : Colors.grey.shade800,
                            fontWeight: _selectedCampusId == 'All'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      ..._campuses.map((campus) {
                        final isSelected = _selectedCampusId == campus.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(campus.name),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCampusId = campus.id);
                                _applyFilter();
                              } else {
                                setState(() => _selectedCampusId = 'All');
                                _applyFilter();
                              }
                            },
                            selectedColor: Colors.indigo.shade100,
                            backgroundColor: Colors.grey.shade200,
                            checkmarkColor: Colors.indigo.shade700,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.indigo.shade800
                                  : Colors.grey.shade800,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadStaff(isRefresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_filteredStaff.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No staff found')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildStaffCard(_filteredStaff[index]),
                    childCount: _filteredStaff.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(Staff staff) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StaffProfileScreen(staff: staff)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          border: Border.all(
            color: staff.isActive
                ? Colors.transparent
                : Colors.red.withValues(alpha: 0.2),
          ),
        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                staff.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!staff.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Inactive',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_android,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              staff.phone,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.deepPurple.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.business,
                                size: 12,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _campusMap[staff.campus] ?? staff.campus,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.deepPurple,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        staff.salaryType == 'Hourly'
                            ? 'Rs ${staff.hourlyRate.toStringAsFixed(0)}/hr'
                            : staff.salaryType == 'Lecture'
                                ? 'Rs ${staff.salary.toStringAsFixed(0)}/lec'
                                : 'Rs ${staff.salary.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        staff.salaryType == 'Hourly'
                            ? 'Hourly'
                            : staff.salaryType == 'Lecture'
                                ? 'Lecture Based'
                                : 'Monthly',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (authProvider.hasPermission('edit_staff') || authProvider.hasPermission('delete_staff'))
                        PopupMenuButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_horiz),
                          itemBuilder: (context) => [
                            if (authProvider.hasPermission('edit_staff'))
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 20),
                                    SizedBox(width: 12),
                                    Text('Edit Profile'),
                                  ],
                                ),
                              ),
                            if (authProvider.hasPermission('delete_staff'))
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') _editStaff(staff);
                            if (value == 'delete') _deleteStaff(staff);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _editStaff(Staff staff) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditStaffScreen(staff: staff)),
    );
    if (result == true) {
      _loadStaff(isRefresh: true);
    }
  }

  Future<void> _deleteStaff(Staff staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${staff.name}?'),
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

    if (confirmed == true) {
      try {
        await _firebaseService.deleteStaff(staff.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadStaff(isRefresh: true);
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
      }
    }
  }
}
