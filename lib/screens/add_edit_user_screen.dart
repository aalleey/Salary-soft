import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/campus.dart';

class AddEditUserScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const AddEditUserScreen({super.key, this.user});

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'admin';
  List<String> _selectedCampuses = [];
  List<Campus> _campuses = [];
  bool _isLoading = false;
  bool _isLoadingCampuses = true;
  bool _obscurePassword = true;

  final Map<String, bool> _permissions = {
    'add_staff': false,
    'edit_staff': false,
    'delete_staff': false,
    'view_staff': false,
    'add_attendance': false,
    'edit_attendance': false,
    'delete_attendance': false,
    'calculate_salary': false,
    'generate_salary_slip': false,
    'view_salary_reports': false,
    'export_reports': false,
    'manage_advances': false,
    'manage_campuses': false,
  };

  bool get isEditing => widget.user != null;

  /// Normalizes any Firestore role string to one of the dropdown values.
  String _normalizeRole(String raw) {
    final normalized = raw.toLowerCase().trim().replaceAll(' ', '_');
    switch (normalized) {
      case 'superuser':
      case 'super_user':
      case 'super_admin':
      case 'app_owner':
      case 'owner':
        return 'superUser';
      case 'admin':
      case 'campus_admin':
        return 'admin';
      default:
        return 'admin';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCampuses();

    if (isEditing) {
      _usernameController.text = widget.user!['username'] ?? '';
      _emailController.text = widget.user!['email'] ?? '';
      _selectedRole = _normalizeRole(widget.user!['role'] ?? 'admin');
      final assignedCampuses = widget.user!['assigned_campuses'] as List<dynamic>?;
      if (assignedCampuses != null && assignedCampuses.isNotEmpty) {
        _selectedCampuses = List<String>.from(assignedCampuses);
      } else {
        // Fallback for legacy data
        final userCampus = widget.user!['campus'] as String?;
        if (userCampus != null && userCampus.isNotEmpty) {
          _selectedCampuses = [userCampus];
        }
      }

      if (widget.user!['permissions'] != null) {
        final Map<String, dynamic> perms = widget.user!['permissions'];
        perms.forEach((key, value) {
          if (_permissions.containsKey(key)) {
            _permissions[key] = value == true;
          }
        });
      }
    }
  }

  Future<void> _loadCampuses() async {
    try {
      final campuses = await _firebaseService.getCampuses();
      if (mounted) {
        setState(() {
          _campuses = campuses;
          _isLoadingCampuses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCampuses = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate campus selection for admin
    if (_selectedRole == 'admin' && _selectedCampuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one campus for the admin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        await _firebaseService.updateUser(
          id: widget.user!['id'],
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
          role: _selectedRole,
          assignedCampuses: _selectedCampuses,
          permissions: _permissions,
        );
      } else {
        await _firebaseService.addUser(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
          assignedCampuses: _selectedCampuses,
          permissions: _permissions,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'User updated successfully'
                  : 'User created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit User' : 'Add User'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.purple.shade300,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withAlpha(50),
                      radius: 30,
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit User Account' : 'Create New User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEditing
                                ? 'Update user details below'
                                : 'Fill in the details to create a new user',
                            style: TextStyle(
                              color: Colors.white.withAlpha(204),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form Card
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: _buildInputDecoration(
                        label: 'Username',
                        icon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration:
                          _buildInputDecoration(
                            label: isEditing
                                ? 'New Password (leave empty to keep current)'
                                : 'Password',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                          ),
                      validator: (value) {
                        if (!isEditing && (value == null || value.isEmpty)) {
                          return 'Please enter password';
                        }
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    const Divider(),
                    const SizedBox(height: 16),

                    const Text(
                      'Role & Access',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role Selector
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: _buildInputDecoration(
                        label: 'Role',
                        icon: Icons.admin_panel_settings_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'superUser',
                          child: Text('Super User (Full Access)'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin (Specific Campuses)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campus Selector
                    _isLoadingCampuses
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRole == 'admin' ? 'Assigned Campuses *' : 'Assigned Campuses (Leave empty for Master Admin)',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._campuses.map((campus) {
                                  final isSelected = _selectedCampuses.contains(campus.name);
                                  return CheckboxListTile(
                                    title: Text(campus.name),
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedCampuses.add(campus.name);
                                        } else {
                                          _selectedCampuses.remove(campus.name);
                                        }
                                      });
                                    },
                                    controlAffinity: ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  );
                                }),
                              ],
                            ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This user will only be able to manage data for the selected campuses.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Permissions Card (Only for admin)
              if (_selectedRole == 'admin') ...[
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Permissions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._permissions.keys.map((String key) {
                        final formattedTitle = key
                            .split('_')
                            .map((word) =>
                                word[0].toUpperCase() + word.substring(1))
                            .join(' ');
                        return CheckboxListTile(
                          title: Text(formattedTitle),
                          value: _permissions[key],
                          onChanged: (bool? value) {
                            setState(() {
                              _permissions[key] = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Save Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
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
                      : Text(
                          isEditing ? 'Update User' : 'Create User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.grey.shade50,
    );
  }
}
