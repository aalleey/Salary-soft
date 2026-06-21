import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/salary.dart';

/// Campus-wise breakdown card for "All Campuses" view
class CampusBreakdownCard extends StatelessWidget {
  final List<Salary> salaries;

  const CampusBreakdownCard({super.key, required this.salaries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Group salaries by campus
    final Map<String, List<Salary>> campusGroups = {};
    for (var salary in salaries) {
      final campus = (salary.campus?.isNotEmpty ?? false)
          ? salary.campus!
          : 'Unknown';
      campusGroups.putIfAbsent(campus, () => []).add(salary);
    }

    // Sort campuses alphabetically
    final sortedCampuses = campusGroups.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.deepPurple.shade900, Colors.purple.shade800]
              : [Colors.deepPurple.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_city,
                  color: Colors.deepPurple.shade400,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus-wise Breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : Colors.deepPurple.shade800,
                      ),
                    ),
                    Text(
                      '${sortedCampuses.length} campuses',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white60
                            : Colors.deepPurple.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedCampuses.map((campus) {
            final campusSalaries = campusGroups[campus]!;
            return _CampusItem(
              campusName: campus,
              salaries: campusSalaries,
              isDark: isDark,
            );
          }),
        ],
      ),
    );
  }
}

class _CampusItem extends StatelessWidget {
  final String campusName;
  final List<Salary> salaries;
  final bool isDark;

  const _CampusItem({
    required this.campusName,
    required this.salaries,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final totalPayable = salaries.fold<double>(
      0,
      (sum, s) => sum + s.totalSalary,
    );
    final totalPaid = salaries
        .where((s) => s.isPaid)
        .fold<double>(0, (sum, s) => sum + s.totalSalary);
    final totalPending = totalPayable - totalPaid;
    final staffCount = salaries.length;
    final paidCount = salaries.where((s) => s.isPaid).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 18,
                      color: Colors.deepPurple.shade400,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        campusName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$staffCount staff',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$paidCount paid',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Total',
                  amount: totalPayable,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatColumn(
                  label: 'Paid',
                  amount: totalPaid,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatColumn(
                  label: 'Pending',
                  amount: totalPending,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalPayable > 0 ? totalPaid / totalPayable : 0,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'en_US');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Rs ${formatter.format(amount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
