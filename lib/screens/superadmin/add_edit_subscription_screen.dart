import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/subscription.dart';
import '../../models/package.dart';
import '../../models/client.dart';
import '../../services/subscription_service.dart';

class AddEditSubscriptionScreen extends StatefulWidget {
  final Subscription? subscription;

  const AddEditSubscriptionScreen({super.key, this.subscription});

  @override
  State<AddEditSubscriptionScreen> createState() => _AddEditSubscriptionScreenState();
}

class _AddEditSubscriptionScreenState extends State<AddEditSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final SubscriptionService _service = SubscriptionService();
  
  bool _isLoading = true;
  List<Client> _clients = [];
  List<Package> _packages = [];

  String? _selectedClientId;
  String? _selectedPackageId;
  String _status = 'active';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.subscription != null) {
      _selectedClientId = widget.subscription!.clientId;
      _selectedPackageId = widget.subscription!.packageId;
      _status = widget.subscription!.status;
      _startDate = widget.subscription!.startDate;
      _endDate = widget.subscription!.endDate;
    }
  }

  Future<void> _loadData() async {
    try {
      final clients = await _service.getClients();
      final packages = await _service.getPackages();
      setState(() {
        _clients = clients;
        _packages = packages;
        
        // Ensure selected values still exist in the fetched lists
        if (_selectedClientId != null && !_clients.any((c) => c.id == _selectedClientId)) {
          _selectedClientId = null;
        }
        if (_selectedPackageId != null && !_packages.any((p) => p.id == _selectedPackageId)) {
          _selectedPackageId = null;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading form data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null || _selectedPackageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Client and a Package')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final pkg = _packages.firstWhere((p) => p.id == _selectedPackageId);
      final sub = Subscription(
        id: widget.subscription?.id ?? '',
        clientId: _selectedClientId!,
        packageId: _selectedPackageId!,
        packageName: pkg.name,
        startDate: _startDate,
        endDate: _endDate,
        status: _status,
        createdAt: widget.subscription?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.subscription == null) {
        await _service.addSubscription(sub);
      } else {
        await _service.updateSubscription(widget.subscription!.id, sub);
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
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
        title: Text(widget.subscription == null ? 'New Subscription' : 'Edit Subscription'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedClientId,
                      decoration: const InputDecoration(labelText: 'Client (Institute)'),
                      items: _clients.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.instituteName} (${c.ownerName})'),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedClientId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPackageId,
                      decoration: const InputDecoration(labelText: 'Package'),
                      items: _packages.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} - ${p.price}'),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedPackageId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('End Date (Expiry)'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Subscription'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
