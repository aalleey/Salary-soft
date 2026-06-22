import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../services/subscription_service.dart';
import '../../providers/auth_provider.dart';

class AddEditClientScreen extends StatefulWidget {
  final Client? client;

  const AddEditClientScreen({super.key, this.client});

  @override
  State<AddEditClientScreen> createState() => _AddEditClientScreenState();
}

class _AddEditClientScreenState extends State<AddEditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final SubscriptionService _service = SubscriptionService();
  
  late TextEditingController _instituteNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;
  String _status = 'active';
  String _currency = 'PKR';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _instituteNameController = TextEditingController(text: widget.client?.instituteName ?? '');
    _ownerNameController = TextEditingController(text: widget.client?.ownerName ?? '');
    _phoneController = TextEditingController(text: widget.client?.phone ?? '');
    _emailController = TextEditingController(text: widget.client?.email ?? '');
    _addressController = TextEditingController(text: widget.client?.address ?? '');
    _passwordController = TextEditingController();
    _status = widget.client?.status ?? 'active';
    _currency = widget.client?.currency ?? 'PKR';
  }

  @override
  void dispose() {
    _instituteNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final clientData = Client(
        id: widget.client?.id ?? '',
        instituteName: _instituteNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        status: _status,
        createdAt: widget.client?.createdAt ?? DateTime.now(),
        createdBy: widget.client?.createdBy ?? authProvider.currentUser?.id ?? 'system',
        currency: _currency,
      );

      if (widget.client == null) {
        await _service.addClient(clientData, password: _passwordController.text);
      } else {
        await _service.updateClient(widget.client!.id, clientData);
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error saving client: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client == null ? 'New Client' : 'Edit Client'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _instituteNameController,
                      decoration: const InputDecoration(labelText: 'Institute Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(labelText: 'Owner Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    if (widget.client == null) ...[
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Login Password'),
                        obscureText: true,
                        validator: (v) => v!.isEmpty ? 'Required for new clients' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: const [
                        DropdownMenuItem(value: 'PKR', child: Text('PKR (Rs)')),
                        DropdownMenuItem(value: 'USD', child: Text('USD (\$ )')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                      ],
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                      ],
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save Client'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
