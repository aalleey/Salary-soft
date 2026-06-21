import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/salary.dart';
import '../models/advance.dart';
import '../shared/widgets/glass_card_widget.dart';

class EmployeeSalaryHistoryScreen extends StatefulWidget {
  final String staffId;
  final String staffName;

  const EmployeeSalaryHistoryScreen({super.key, required this.staffId, required this.staffName});

  @override
  State<EmployeeSalaryHistoryScreen> createState() => _EmployeeSalaryHistoryScreenState();
}

class _EmployeeSalaryHistoryScreenState extends State<EmployeeSalaryHistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<Salary> _salaries = [];
  List<Advance> _advances = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Get all salaries for this staff
      final salaries = await _firebaseService.getSalaries(staffId: widget.staffId);
      // Get all advances for this staff
      final (advances, _) = await _firebaseService.getAdvances(staffId: widget.staffId, limit: 100);

      if (mounted) {
        setState(() {
          _salaries = salaries..sort((a, b) {
            // Sort by year, then month descending
            if (b.year != a.year) return b.year.compareTo(a.year);
            return b.month.compareTo(a.month);
          });
          _advances = advances;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('${widget.staffName} History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Salaries'),
              Tab(text: 'Advances'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildSalariesTab(isDark, theme),
                  _buildAdvancesTab(isDark, theme),
                ],
              ),
      ),
    );
  }

  Widget _buildSalariesTab(bool isDark, ThemeData theme) {
    if (_salaries.isEmpty) {
      return const Center(child: Text('No salary history found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _salaries.length,
      itemBuilder: (context, index) {
        final salary = _salaries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        salary.monthYearText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: salary.statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          salary.statusText,
                          style: TextStyle(color: salary.statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn('Net Payable', salary.totalSalary),
                      _buildStatColumn('Paid Amount', salary.paidAmount, color: Colors.green),
                      _buildStatColumn('Remaining', salary.remainingAmount, color: Colors.orange),
                    ],
                  ),
                  if (salary.notes != null && salary.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Notes: ${salary.notes}', style: TextStyle(color: theme.hintColor, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancesTab(bool isDark, ThemeData theme) {
    if (_advances.isEmpty) {
      return const Center(child: Text('No advance history found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _advances.length,
      itemBuilder: (context, index) {
        final advance = _advances[index];
        final date = DateTime.tryParse(advance.advanceDate) ?? DateTime.now();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.money_off, color: Colors.white),
              ),
              title: Text('Rs ${NumberFormat('#,##0').format(advance.advanceAmount)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Date: ${DateFormat('MMM d, yyyy').format(date)}'),
                  if (advance.description != null && advance.description!.isNotEmpty)
                    Text('Reason: ${advance.description}'),
                  Text('Deduct in: ${DateFormat('MMM yyyy').format(DateTime(advance.advanceYear, advance.advanceMonth))}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, double value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          'Rs ${NumberFormat.compact().format(value)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
        ),
      ],
    );
  }
}
