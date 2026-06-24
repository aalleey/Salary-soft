class SalaryCalculationResult {
  final double grossSalary;
  final double deduction; // includes absent penalty, advance, otherDeductions
  final double totalSalary;
  final String details;

  SalaryCalculationResult({
    required this.grossSalary,
    required this.deduction,
    required this.totalSalary,
    required this.details,
  });
}

class SalaryCalculationService {
  /// Performs the mathematical calculation of a staff member's salary.
  static SalaryCalculationResult calculateSalary({
    required String salaryType, // 'monthly', 'hourly', 'lecture_based'
    required double basicSalary, // Monthly base salary or rate per lecture
    required double hourlyRate, // Hourly rate
    required double workingHours, // Total hours worked (for hourly)
    required double workingDays, // Present days count (for monthly present_based) or lectures count
    required double absents, // Absent days count
    required double lates, // Late arrivals count
    required double halfLeaves, // Half day leaves count
    required double advance, // Advance amount taken
    required double otherDeductions, // Extra manual deductions
    required double bonus, // Extra manual bonus
    String calculationType = 'absent_based', // 'absent_based' or 'present_based'
  }) {
    double grossSalary = 0.0;
    double deduction = 0.0;
    String details = '';

    final type = salaryType.toLowerCase().replaceAll(' ', '_');

    if (type == 'hourly') {
      grossSalary = workingHours * hourlyRate;
      deduction = advance + otherDeductions;
      double finalSalary = grossSalary - deduction + bonus;
      if (finalSalary < 0) finalSalary = 0.0;
      
      details = '${workingHours.toStringAsFixed(1)} hours × ${hourlyRate.toStringAsFixed(0)} PKR/hr';
      return SalaryCalculationResult(
        grossSalary: grossSalary,
        deduction: deduction,
        totalSalary: finalSalary,
        details: details,
      );
    } else if (type == 'lecture_based') {
      // For lecture-based, we interpret workingDays or workingHours as total lectures count
      final lectures = workingDays > 0 ? workingDays : workingHours;
      grossSalary = lectures * basicSalary; // basicSalary represents rate per lecture
      deduction = advance + otherDeductions;
      double finalSalary = grossSalary - deduction + bonus;
      if (finalSalary < 0) finalSalary = 0.0;

      details = '${lectures.toStringAsFixed(0)} lectures × ${basicSalary.toStringAsFixed(0)} PKR/lecture';
      return SalaryCalculationResult(
        grossSalary: grossSalary,
        deduction: deduction,
        totalSalary: finalSalary,
        details: details,
      );
    } else {
      // Monthly Salary
      grossSalary = basicSalary;
      double perDaySalary = basicSalary / 30.0;

      if (calculationType == 'present_based') {
        // Gross is computed from present days
        grossSalary = workingDays * perDaySalary;
        deduction = advance + otherDeductions;
        double finalSalary = grossSalary - deduction + bonus;
        if (finalSalary < 0) finalSalary = 0.0;

        details = '${workingDays.toStringAsFixed(1)} presents × ${perDaySalary.toStringAsFixed(1)} PKR/day';
        return SalaryCalculationResult(
          grossSalary: grossSalary,
          deduction: deduction,
          totalSalary: finalSalary,
          details: details,
        );
      } else {
        // Absent-based (default)
        double absentDeduction = absents * perDaySalary;
        deduction = absentDeduction + advance + otherDeductions;
        double finalSalary = basicSalary - deduction + bonus;
        if (finalSalary < 0) finalSalary = 0.0;

        details = 'Basic: ${basicSalary.toStringAsFixed(0)} PKR - (${absents.toStringAsFixed(1)} absents × ${perDaySalary.toStringAsFixed(1)} PKR/day)';
        return SalaryCalculationResult(
          grossSalary: grossSalary,
          deduction: deduction,
          totalSalary: finalSalary,
          details: details,
        );
      }
    }
  }
}
