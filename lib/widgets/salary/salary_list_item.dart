import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/salary.dart';

/// Individual salary list item widget with expandable details
class SalaryListItem extends StatelessWidget {
  final Salary salary;
  final bool isStaffDeleted;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTogglePaid;
  final VoidCallback onPrintSlip;
  final VoidCallback onRecalculate;
  final VoidCallback onPayAdvance;
  final VoidCallback onDelete;
  final VoidCallback? onSelectionToggle;
  final bool isSuperAdmin;
  final int index;

  const SalaryListItem({
    super.key,
    required this.salary,
    required this.isStaffDeleted,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onTogglePaid,
    required this.onPrintSlip,
    required this.onRecalculate,
    required this.onPayAdvance,
    required this.onDelete,
    this.onSelectionToggle,
    required this.isSuperAdmin,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.deepPurple.withOpacity(0.5)
                : isStaffDeleted
                ? Colors.red.withOpacity(0.3)
                : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: _buildLeading(context),
            title: _buildTitle(context),
            subtitle: Text(
              salary.campus ?? 'No campus',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            trailing: _buildTrailing(context),
            children: [_buildExpandedDetails(context, isDark)],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (isSelectionMode) {
      return GestureDetector(
        onTap: onSelectionToggle,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.deepPurple
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSelected ? Icons.check : Icons.circle_outlined,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            size: 22,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: isStaffDeleted
          ? Colors.grey.withOpacity(0.2)
          : (salary.isPaid
                ? Colors.green.withOpacity(0.15)
                : Colors.deepPurple.withOpacity(0.15)),
      child: isStaffDeleted
          ? const Icon(Icons.person_off, color: Colors.grey, size: 20)
          : (salary.isPaid
                ? const Icon(Icons.check, color: Colors.green, size: 20)
                : Text(
                    salary.staffName.isNotEmpty
                        ? salary.staffName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            salary.staffName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isStaffDeleted
                  ? theme.colorScheme.onSurface.withOpacity(0.4)
                  : theme.colorScheme.onSurface,
              decoration: isStaffDeleted ? TextDecoration.lineThrough : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isStaffDeleted)
          _StatusBadge(text: 'Deleted', color: Colors.red)
        else if (salary.isPaid)
          _StatusBadge(text: 'PAID', color: Colors.green),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Payable',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        Text(
          'Rs ${NumberFormat('#,##0').format(salary.totalSalary)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: salary.isPaid ? Colors.green : Colors.green.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            _DetailRow(
              label: 'Basic Salary',
              value: salary.basicSalary,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              label: 'Lates',
              value: salary.lates.toDouble(),
              color: Colors.orange,
              isCount: true,
              suffix: ' times',
            ),
            const SizedBox(height: 10),
            _DetailRow(
              label: 'Absents',
              value: salary.absents,
              color: Colors.orange.shade700,
              isCount: true,
              suffix: ' days',
            ),
            const SizedBox(height: 10),
            _DetailRow(
              label: 'Advance Given',
              value: salary.advanceAmount,
              color: Colors.orange.shade800,
            ),
            Divider(height: 24, color: Theme.of(context).dividerColor),
            _DetailRow(
              label: 'Total Deductions',
              value: salary.deduction,
              color: Colors.red,
              isBold: true,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              label: 'Total Payable',
              value: salary.totalSalary,
              color: Colors.green,
              isBold: true,
            ),
            if (salary.isPaid && salary.paidDate != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Paid on ${DateFormat('MMM d, y').format(DateTime.parse(salary.paidDate!))}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _ActionButtons(
              salary: salary,
              isStaffDeleted: isStaffDeleted,
              isSuperAdmin: isSuperAdmin,
              onTogglePaid: onTogglePaid,
              onPrintSlip: onPrintSlip,
              onRecalculate: onRecalculate,
              onPayAdvance: onPayAdvance,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isCount;
  final bool isBold;
  final String suffix;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.color,
    this.isCount = false,
    this.isBold = false,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = isCount
        ? '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}$suffix'
        : 'Rs ${NumberFormat('#,##0').format(value)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          displayValue,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Salary salary;
  final bool isStaffDeleted;
  final bool isSuperAdmin;
  final VoidCallback onTogglePaid;
  final VoidCallback onPrintSlip;
  final VoidCallback onRecalculate;
  final VoidCallback onPayAdvance;
  final VoidCallback onDelete;

  const _ActionButtons({
    required this.salary,
    required this.isStaffDeleted,
    required this.isSuperAdmin,
    required this.onTogglePaid,
    required this.onPrintSlip,
    required this.onRecalculate,
    required this.onPayAdvance,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isStaffDeleted && isSuperAdmin)
          _IconActionButton(
            icon: Icons.delete_outline,
            color: Colors.red,
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        if (!isStaffDeleted)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onTogglePaid,
              icon: Icon(
                salary.isPaid ? Icons.undo : Icons.check_circle_outline,
                size: 16,
              ),
              label: Text(
                salary.isPaid ? 'Mark Unpaid' : 'Mark Paid',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: salary.isPaid
                    ? Theme.of(context).cardColor
                    : Colors.green,
                foregroundColor: salary.isPaid
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white,
                elevation: salary.isPaid ? 0 : 2,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: salary.isPaid
                      ? BorderSide(color: Theme.of(context).dividerColor)
                      : BorderSide.none,
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        _IconActionButton(
          icon: Icons.print,
          color: Colors.blue,
          tooltip: 'Print Slip',
          onPressed: onPrintSlip,
        ),
        if (!isStaffDeleted && !salary.isPaid) ...[
          const SizedBox(width: 8),
          _IconActionButton(
            icon: Icons.payments,
            color: Colors.orange,
            tooltip: 'Pay Advance',
            onPressed: onPayAdvance,
          ),
        ],
        const SizedBox(width: 8),
        _IconActionButton(
          icon: Icons.refresh,
          color: Colors.deepPurple,
          tooltip: 'Recalculate',
          onPressed: onRecalculate,
        ),
        if (isStaffDeleted && isSuperAdmin) ...[
          const SizedBox(width: 8),
          _IconActionButton(
            icon: Icons.delete_outline,
            color: Colors.red,
            tooltip: 'Remove',
            onPressed: onDelete,
          ),
        ],
      ],
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color,
        tooltip: tooltip,
        constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
      ),
    );
  }
}
