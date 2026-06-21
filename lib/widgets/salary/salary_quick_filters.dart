import 'package:flutter/material.dart';

/// Quick filter options for salary status
enum SalaryQuickFilter { all, paidOnly, unpaidOnly }

/// Sorting options for salary list
enum SalarySortOption { name, amountHigh, amountLow, status }

/// Quick filter chips and sorting dropdown widget
class SalaryQuickFilters extends StatelessWidget {
  final SalaryQuickFilter selectedFilter;
  final SalarySortOption selectedSort;
  final ValueChanged<SalaryQuickFilter> onFilterChanged;
  final ValueChanged<SalarySortOption> onSortChanged;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;

  const SalaryQuickFilters({
    super.key,
    required this.selectedFilter,
    required this.selectedSort,
    required this.onFilterChanged,
    required this.onSortChanged,
    this.isSelectionMode = false,
    this.selectedCount = 0,
    required this.onSelectAll,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isSelectionMode
          ? _buildSelectionModeBar(context)
          : _buildFilterBar(context),
    );
  }

  Widget _buildSelectionModeBar(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$selectedCount selected',
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const Spacer(),
        TextButton(onPressed: onSelectAll, child: const Text('Select All')),
        TextButton(
          onPressed: onClearSelection,
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('Clear'),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Row(
      children: [
        // Quick Filter Chips
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  icon: Icons.list,
                  isSelected: selectedFilter == SalaryQuickFilter.all,
                  onTap: () => onFilterChanged(SalaryQuickFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Paid',
                  icon: Icons.check_circle,
                  isSelected: selectedFilter == SalaryQuickFilter.paidOnly,
                  selectedColor: Colors.green,
                  onTap: () => onFilterChanged(SalaryQuickFilter.paidOnly),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Unpaid',
                  icon: Icons.schedule,
                  isSelected: selectedFilter == SalaryQuickFilter.unpaidOnly,
                  selectedColor: Colors.orange,
                  onTap: () => onFilterChanged(SalaryQuickFilter.unpaidOnly),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Sort Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SalarySortOption>(
              value: selectedSort,
              icon: const Icon(Icons.sort, size: 18),
              isDense: true,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              items: const [
                DropdownMenuItem(
                  value: SalarySortOption.name,
                  child: Text('Name'),
                ),
                DropdownMenuItem(
                  value: SalarySortOption.amountHigh,
                  child: Text('Amount ↓'),
                ),
                DropdownMenuItem(
                  value: SalarySortOption.amountLow,
                  child: Text('Amount ↑'),
                ),
                DropdownMenuItem(
                  value: SalarySortOption.status,
                  child: Text('Status'),
                ),
              ],
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color? selectedColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? Colors.deepPurple;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
