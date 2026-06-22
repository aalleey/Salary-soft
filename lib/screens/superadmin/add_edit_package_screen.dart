import 'package:flutter/material.dart';
import '../../models/package.dart';
import '../../services/subscription_service.dart';

class AddEditPackageScreen extends StatefulWidget {
  final Package? package;

  const AddEditPackageScreen({super.key, this.package});

  @override
  State<AddEditPackageScreen> createState() => _AddEditPackageScreenState();
}

class _AddEditPackageScreenState extends State<AddEditPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final SubscriptionService _service = SubscriptionService();
  
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _maxStaffController;
  late TextEditingController _maxCampusesController;
  late TextEditingController _featureController;
  bool _isActive = true;
  List<String> _features = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.package?.name ?? '');
    _priceController = TextEditingController(text: widget.package?.price.toString() ?? '');
    _maxStaffController = TextEditingController(text: widget.package?.staffLimit.toString() ?? '');
    _maxCampusesController = TextEditingController(text: widget.package?.campusLimit.toString() ?? '');
    _featureController = TextEditingController();

    _isActive = widget.package?.isActive ?? true;
    _features = widget.package?.features != null ? List.from(widget.package!.features) : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _maxStaffController.dispose();
    _maxCampusesController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final pkg = Package(
        id: widget.package?.id ?? '',
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        staffLimit: int.tryParse(_maxStaffController.text) ?? 0,
        campusLimit: int.tryParse(_maxCampusesController.text) ?? 0,
        features: _features,
        isActive: _isActive,
        createdAt: widget.package?.createdAt ?? DateTime.now(),
      );

      if (widget.package == null) {
        await _service.addPackage(pkg);
      } else {
        await _service.updatePackage(widget.package!.id, pkg);
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

  void _addFeature() {
    final f = _featureController.text.trim();
    if (f.isNotEmpty && !_features.contains(f)) {
      setState(() {
        _features.add(f);
        _featureController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.package == null ? 'New Package' : 'Edit Package'),
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Package Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Price (Monthly)'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _maxStaffController,
                            decoration: const InputDecoration(labelText: 'Max Staff (0=Unlimited)'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxCampusesController,
                            decoration: const InputDecoration(labelText: 'Max Campuses'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('Is Active'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    const Divider(height: 32),
                    const Text('Features', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _featureController,
                            decoration: const InputDecoration(
                              labelText: 'Add Feature',
                              isDense: true,
                            ),
                            onFieldSubmitted: (_) => _addFeature(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.deepPurple),
                          onPressed: _addFeature,
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _features.map((f) => Chip(
                        label: Text(f),
                        onDeleted: () => setState(() => _features.remove(f)),
                      )).toList(),
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
                        child: const Text('Save Package'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
