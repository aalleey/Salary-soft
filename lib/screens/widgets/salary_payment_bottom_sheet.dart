import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/salary.dart';
import '../../services/firebase_service.dart';
import '../employee_salary_history_screen.dart';

class SalaryPaymentBottomSheet extends StatefulWidget {
  final Salary salary;

  const SalaryPaymentBottomSheet({super.key, required this.salary});

  @override
  State<SalaryPaymentBottomSheet> createState() => _SalaryPaymentBottomSheetState();
}

class _SalaryPaymentBottomSheetState extends State<SalaryPaymentBottomSheet> {
  final FirebaseService _firebaseService = FirebaseService();
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to remaining amount
    final remaining = widget.salary.remainingAmount;
    _amountController = TextEditingController(text: remaining > 0 ? remaining.toStringAsFixed(0) : '');
    _notesController = TextEditingController(text: widget.salary.notes ?? '');
    if (widget.salary.paidDate != null) {
      try {
        _selectedDate = DateTime.parse(widget.salary.paidDate!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    // Determine status
    final totalPaidNow = widget.salary.paidAmount + amount;
    String newStatus = 'Pending';
    if (totalPaidNow >= widget.salary.totalSalary) {
      newStatus = 'Paid';
    } else if (totalPaidNow > 0) {
      newStatus = 'Partial Paid';
    }

    setState(() => _isLoading = true);

    try {
      await _firebaseService.paySalary(
        widget.salary.id,
        totalPaidNow,
        _selectedDate.toIso8601String(),
        _notesController.text.trim(),
        newStatus,
        widget.salary.totalSalary,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment updated to $newStatus'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Process Payment',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeSalaryHistoryScreen(
                          staffId: widget.salary.staffId,
                          staffName: widget.salary.staffName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('History'),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.salary.staffName} • ${widget.salary.shortMonthYearText}',
              style: TextStyle(color: theme.hintColor, fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Overview Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Basic Salary', widget.salary.basicSalary, theme),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Absents/Lates Deduction', -widget.salary.deduction + widget.salary.advanceAmount, theme, isDeduction: true),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Advances Deduction', -widget.salary.advanceAmount, theme, isDeduction: true),
                  const Divider(height: 24),
                  _buildSummaryRow('Net Payable', widget.salary.totalSalary, theme, isBold: true),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Already Paid', widget.salary.paidAmount, theme, color: Colors.green),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Remaining Balance', widget.salary.remainingAmount, theme, isBold: true, color: Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount to Pay Now (Rs)',
                prefixIcon: const Icon(Icons.payments_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Payment Date',
                  prefixIcon: const Icon(Icons.calendar_today_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Payment Note (Optional)',
                prefixIcon: const Icon(Icons.notes_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            
            // Actions
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, ThemeData theme, {bool isDeduction = false, bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? theme.textTheme.bodyLarge?.color : theme.hintColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          'Rs ${NumberFormat('#,##0').format(value.abs())}',
          style: TextStyle(
            color: color ?? (isDeduction ? Colors.red : (isBold ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodyMedium?.color)),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
