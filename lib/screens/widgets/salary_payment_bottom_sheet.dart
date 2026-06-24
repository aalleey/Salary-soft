import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/salary.dart';
import '../../services/firebase_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/advance.dart';
import '../employee_salary_history_screen.dart';
import '../../services/salary_calculation_service.dart';

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
  late TextEditingController _bonusController;
  late TextEditingController _deductionsController;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  double _calculatedNetPayable = 0.0;
  double _calculatedDeductions = 0.0;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.salary.notes ?? '');
    _bonusController = TextEditingController(text: widget.salary.bonus.toStringAsFixed(0));
    _deductionsController = TextEditingController(text: widget.salary.otherDeductions.toStringAsFixed(0));
    
    _calculatedNetPayable = widget.salary.totalSalary;
    _calculatedDeductions = widget.salary.deduction;

    final remaining = widget.salary.remainingAmount;
    _amountController = TextEditingController(text: remaining > 0 ? remaining.toStringAsFixed(0) : '');

    if (widget.salary.paidDate != null) {
      try {
        _selectedDate = DateTime.parse(widget.salary.paidDate!);
      } catch (_) {}
    }

    _bonusController.addListener(_recalculateLiveSalary);
    _deductionsController.addListener(_recalculateLiveSalary);
  }

  void _recalculateLiveSalary() {
    final double bonusVal = double.tryParse(_bonusController.text) ?? 0.0;
    final double otherDeductionsVal = double.tryParse(_deductionsController.text) ?? 0.0;
    
    double baseSalaryForCalc = widget.salary.basicSalary;
    if (widget.salary.salaryType == 'hourly') {
      baseSalaryForCalc = 0.0;
    } else if (widget.salary.salaryType == 'lecture_based') {
      baseSalaryForCalc = widget.salary.workingDays > 0 
          ? (widget.salary.basicSalary / widget.salary.workingDays) 
          : 0.0;
    } else {
      // Monthly
      final isPresentBased = widget.salary.calculationDetails?.contains('presents') ?? false;
      if (isPresentBased && widget.salary.workingDays > 0) {
        baseSalaryForCalc = widget.salary.basicSalary * 30.0 / widget.salary.workingDays;
      }
    }

    final isPresentBased = widget.salary.calculationDetails?.contains('presents') ?? false;
    final calcResult = SalaryCalculationService.calculateSalary(
      salaryType: widget.salary.salaryType,
      basicSalary: baseSalaryForCalc,
      hourlyRate: widget.salary.hourlyRate,
      workingHours: widget.salary.totalHours,
      workingDays: widget.salary.workingDays,
      absents: widget.salary.absents,
      lates: widget.salary.lates.toDouble(),
      halfLeaves: 0.0,
      advance: widget.salary.advanceAmount,
      otherDeductions: otherDeductionsVal,
      bonus: bonusVal,
      calculationType: isPresentBased ? 'present_based' : 'absent_based',
    );

    setState(() {
      _calculatedNetPayable = calcResult.totalSalary;
      _calculatedDeductions = calcResult.deduction;
      
      final double paid = widget.salary.paidAmount;
      final double remaining = _calculatedNetPayable - paid;
      _amountController.text = remaining > 0 ? remaining.toStringAsFixed(0) : '';
    });
  }

  @override
  void dispose() {
    _bonusController.removeListener(_recalculateLiveSalary);
    _deductionsController.removeListener(_recalculateLiveSalary);
    _amountController.dispose();
    _notesController.dispose();
    _bonusController.dispose();
    _deductionsController.dispose();
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

    final double bonusVal = double.tryParse(_bonusController.text) ?? 0.0;
    final double otherDeductionsVal = double.tryParse(_deductionsController.text) ?? 0.0;
    
    final remainingBalance = _calculatedNetPayable - widget.salary.paidAmount;

    // Handle overpayment
    if (amount > remainingBalance && remainingBalance > 0) {
      final excess = amount - remainingBalance;
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Amount Exceeds Balance'),
          content: Text('The entered amount (Rs ${amount.toStringAsFixed(0)}) exceeds the remaining balance (Rs ${remainingBalance.toStringAsFixed(0)}) by Rs ${excess.toStringAsFixed(0)}.\n\nHow would you like to handle this overpayment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: const Text('Cancel Payment', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Convert to advance
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: Text('Convert Rs ${excess.toStringAsFixed(0)} to Advance', style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      );

      if (confirm == null || confirm == false) {
        return; // User canceled or dismissed dialog
      }

      if (!mounted) return;

      // User chose to convert to advance
      setState(() => _isLoading = true);
      try {
        // 1. Pay exactly the remaining balance
        final totalPaidNow = widget.salary.paidAmount + remainingBalance;
        await _firebaseService.updateSalaryPayment(
          salaryId: widget.salary.id,
          bonus: bonusVal,
          otherDeductions: otherDeductionsVal,
          totalDeduction: _calculatedDeductions,
          totalSalary: _calculatedNetPayable,
          paidAmount: totalPaidNow,
          paidDate: _selectedDate.toIso8601String(),
          notes: _notesController.text.trim(),
          status: 'Paid', // Status is Paid since we cover the remaining balance
        );

        // 2. Create the advance for next month
        DateTime nextMonthDate;
        if (widget.salary.month == 12) {
          nextMonthDate = DateTime(widget.salary.year + 1, 1, 1);
        } else {
          nextMonthDate = DateTime(widget.salary.year, widget.salary.month + 1, 1);
        }

        final advance = Advance(
          id: '', // Will be generated by FirebaseService
          staffId: widget.salary.staffId,
          staffName: widget.salary.staffName,
          advanceAmount: excess,
          advanceDate: _selectedDate.toIso8601String(),
          advanceMonth: nextMonthDate.month,
          advanceYear: nextMonthDate.year,
          description: 'Excess amount converted from salary payment for ${widget.salary.shortMonthYearText}',
          notes: _notesController.text.trim(),
        );

        await _firebaseService.addAdvance(advance);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment completed and Advance created successfully!'), backgroundColor: Colors.green),
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
      return;
    }

    // Determine status for normal payment
    final totalPaidNow = widget.salary.paidAmount + amount;
    String newStatus = 'Pending';
    if (totalPaidNow >= _calculatedNetPayable && _calculatedNetPayable > 0) {
      newStatus = 'Paid';
    } else if (totalPaidNow > 0) {
      newStatus = 'Partial Paid';
    }

    setState(() => _isLoading = true);

    try {
      await _firebaseService.updateSalaryPayment(
        salaryId: widget.salary.id,
        bonus: bonusVal,
        otherDeductions: otherDeductionsVal,
        totalDeduction: _calculatedDeductions,
        totalSalary: _calculatedNetPayable,
        paidAmount: totalPaidNow,
        paidDate: _selectedDate.toIso8601String(),
        notes: _notesController.text.trim(),
        status: newStatus,
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
                if (Provider.of<AuthProvider>(context, listen: false).activeCampus == null || Provider.of<AuthProvider>(context, listen: false).activeCampus!.isEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'recalculate') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Recalculate Salary'),
                            content: const Text('Are you sure you want to recalculate this salary based on current attendance and advances?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Recalculate')),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          setState(() => _isLoading = true);
                          try {
                            await _firebaseService.recalculateAndSaveSalary(
                              widget.salary.staffId,
                              widget.salary.month,
                              widget.salary.year,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary recalculated successfully'), backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Salary'),
                            content: const Text('Are you sure you want to delete this salary record? This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          setState(() => _isLoading = true);
                          try {
                            await _firebaseService.deleteSalary(widget.salary.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary deleted successfully'), backgroundColor: Colors.green));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'recalculate', child: Text('Recalculate Salary')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Salary', style: TextStyle(color: Colors.red))),
                    ],
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
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
                  if (widget.salary.salaryType == 'hourly') ...[
                    _buildSummaryRow('Hourly Rate', widget.salary.hourlyRate, theme),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Working Hours', widget.salary.totalHours, theme, showCurrency: false),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Gross Salary', widget.salary.hourlyRate * widget.salary.totalHours, theme),
                  ] else if (widget.salary.salaryType == 'lecture_based') ...[
                    _buildSummaryRow('Lecture Rate', widget.salary.workingDays > 0 ? (widget.salary.basicSalary / widget.salary.workingDays) : widget.salary.basicSalary, theme),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Lectures Conducted', widget.salary.workingDays, theme, showCurrency: false),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Gross Salary', widget.salary.basicSalary, theme),
                  ] else ...[
                    _buildSummaryRow('Basic Salary', widget.salary.basicSalary, theme),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Absents Deduction', -(widget.salary.deduction - widget.salary.advanceAmount - widget.salary.otherDeductions), theme, isDeduction: true),
                  ],
                  const SizedBox(height: 8),
                  _buildSummaryRow('Advances Deduction', -widget.salary.advanceAmount, theme, isDeduction: true),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Bonus', double.tryParse(_bonusController.text) ?? 0.0, theme, color: Colors.green),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Other Deductions', -(double.tryParse(_deductionsController.text) ?? 0.0), theme, isDeduction: true),
                  const Divider(height: 24),
                  _buildSummaryRow('Net Payable', _calculatedNetPayable, theme, isBold: true),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Already Paid', widget.salary.paidAmount, theme, color: Colors.green),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Remaining Balance', _calculatedNetPayable - widget.salary.paidAmount, theme, isBold: true, color: Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'ADJUSTMENTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bonusController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Bonus (Rs)',
                      prefixIcon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _deductionsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Deductions (Rs)',
                      prefixIcon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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

  Widget _buildSummaryRow(String label, double value, ThemeData theme, {bool isDeduction = false, bool isBold = false, Color? color, bool showCurrency = true}) {
    final valueText = showCurrency
        ? 'Rs ${NumberFormat('#,##0').format(value.abs())}'
        : NumberFormat('#,##0.#').format(value.abs());

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
          valueText,
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
