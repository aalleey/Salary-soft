import 'package:flutter/material.dart';

/// Filter bar widget with campus selector, year dropdown, month chips, and search
class SalaryFilterBar extends StatelessWidget {
  final List<String> campusNames;
  final String? selectedCampus;
  final int selectedYear;
  final int selectedMonth;
  final String searchQuery;
  final bool isLoadingCampuses;
  final bool showCampusFilter;
  final ValueChanged<String?> onCampusChanged;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<String> onSearchChanged;

  static const List<String> monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  const SalaryFilterBar({
    super.key,
    required this.campusNames,
    required this.selectedCampus,
    required this.selectedYear,
    required this.selectedMonth,
    required this.searchQuery,
    required this.isLoadingCampuses,
    required this.showCampusFilter,
    required this.onCampusChanged,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        _buildSearchBar(context, isDark),
        const SizedBox(height: 16),

        // Campus Selector (Only for Admins)
        if (showCampusFilter) ...[
          _buildCampusSelector(context, isDark),
          const SizedBox(height: 16),
        ],

        // Year Selector
        _buildYearSelector(context, isDark),
        const SizedBox(height: 16),

        // Month Chips
        _buildMonthChips(context, isDark),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search staff by name...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onSearchChanged(''),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCampusSelector(BuildContext context, bool isDark) {
    if (isLoadingCampuses) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCampus,
          hint: Text(
            'Select Campus',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          isExpanded: true,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          dropdownColor: Theme.of(context).cardColor,
          items: campusNames.map((name) {
            return DropdownMenuItem<String>(
              value: name,
              child: Row(
                children: [
                  Icon(
                    name == 'All Campuses' ? Icons.public : Icons.location_city,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(name),
                ],
              ),
            );
          }).toList(),
          onChanged: onCampusChanged,
        ),
      ),
    );
  }

  Widget _buildYearSelector(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Year:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedYear,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
                dropdownColor: Theme.of(context).cardColor,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - 2 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  if (value != null) onYearChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChips(BuildContext context, bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final isSelected = month == selectedMonth;

          return GestureDetector(
            onTap: () => onMonthChanged(month),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          Colors.deepPurple.shade600,
                          Colors.purple.shade500,
                        ],
                      )
                    : null,
                color: isSelected ? null : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? null
                    : Border.all(color: Theme.of(context).dividerColor),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  monthNames[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
