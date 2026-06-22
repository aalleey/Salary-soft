import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart';
import '../../models/client.dart';
import '../../services/payment_service.dart';
import '../../services/subscription_service.dart';
import '../../providers/auth_provider.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final PaymentService _paymentService = PaymentService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  List<Client> _clients = [];

  String? _selectedClientId;
  late TextEditingController _amountController;
  late TextEditingController _referenceController;
  late TextEditingController _notesController;

  String _currency = 'PKR';
  String _paymentMethod = 'cash';
  String _status = 'completed';

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _referenceController = TextEditingController();
    _notesController = TextEditingController();
    _loadClients();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _subscriptionService.getClients();
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading clients: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a Client')));
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final payment = Payment(
        id: '',
        clientId: _selectedClientId!,
        subscriptionId:
            '', // Ideally linked, but manual payments might be loose
        amount: double.tryParse(_amountController.text) ?? 0.0,
        paymentMethod: _paymentMethod,
        transactionId: _referenceController.text.trim(),
        paymentDate: DateTime.now(),
        month: DateTime.now().month,
        year: DateTime.now().year,
        status: _status,
        notes: _notesController.text.trim(),
        recordedBy: authProvider.currentUser?.id ?? 'system',
        createdAt: DateTime.now(),
      );

      await _paymentService.recordPayment(payment);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Manual Payment')),
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
                      decoration: const InputDecoration(
                        labelText: 'Client (Institute)',
                      ),
                      items: _clients
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                '${c.instituteName} (${c.ownerName})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedClientId = v;
                          // Auto-select client's currency if available
                          final client = _clients.firstWhere((c) => c.id == v);
                          _currency = client.currency;
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'PKR',
                                child: Text('PKR'),
                              ),
                              DropdownMenuItem(
                                value: 'USD',
                                child: Text('USD'),
                              ),
                              DropdownMenuItem(
                                value: 'EUR',
                                child: Text('EUR'),
                              ),
                              DropdownMenuItem(
                                value: 'GBP',
                                child: Text('GBP'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _currency = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(
                          value: 'bank_transfer',
                          child: Text('Bank Transfer'),
                        ),
                        DropdownMenuItem(
                          value: 'jazzcash',
                          child: Text('JazzCash'),
                        ),
                        DropdownMenuItem(
                          value: 'easypaisa',
                          child: Text('EasyPaisa'),
                        ),
                        DropdownMenuItem(
                          value: 'card',
                          child: Text('Credit/Debit Card'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Reference ID / Trx ID',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'failed',
                          child: Text('Failed'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Record Payment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
