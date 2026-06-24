import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/salary.dart';

class PdfService {
  final _currencyFormat = NumberFormat('#,##0');

  // Brand Colors
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF2E0249);
  static const PdfColor accentColor = PdfColor.fromInt(0xFFF806CC);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF4A148C);
  static const PdfColor lightBg = PdfColor.fromInt(0xFFF3E5F5);

  Future<Uint8List> generateMonthlyReport(
    List<Salary> salaries,
    int month,
    int year,
    String? campus,
  ) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM').format(DateTime(year, month));
    final reportDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.now());

    // Group by campus for breakdown if showing all
    final Map<String, List<Salary>> campusGroups = {};
    if (campus == null) {
      for (var salary in salaries) {
        final campusName = (salary.campus?.isNotEmpty ?? false)
            ? salary.campus!
            : 'Unknown';
        campusGroups.putIfAbsent(campusName, () => []).add(salary);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          'Monthly Salary Report',
          '$monthName $year',
          campus ?? 'All Campuses',
          reportDate,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          if (campus == null && campusGroups.length > 1) ...[
            _buildSectionTitle('Campus Breakdown'),
            _buildCampusBreakdownTable(campusGroups),
            pw.SizedBox(height: 20),
          ],
          _buildSectionTitle('Staff Salary Details'),
          _buildSalaryTable(salaries),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [_buildSummaryCard(salaries)],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generatePayslip(Salary salary) async {
    final pdf = pw.Document();
    final monthName = DateFormat(
      'MMMM',
    ).format(DateTime(salary.year, salary.month));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => _buildPayslipContent(salary, monthName),
      ),
    );
    return pdf.save();
  }

  pw.Widget _buildHeader(
    String title,
    String subtitle,
    String campus,
    String date,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: secondaryColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: lightBg,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    campus,
                    style: pw.TextStyle(fontSize: 10, color: primaryColor),
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'SALARY SYSTEM',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Generated: $date',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(color: primaryColor, thickness: 2),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Confidential Document',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: secondaryColor,
        ),
      ),
    );
  }

  pw.Widget _buildCampusBreakdownTable(Map<String, List<Salary>> groups) {
    final sortedKeys = groups.keys.toList()..sort();

    return pw.TableHelper.fromTextArray(
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      headers: [
        'Campus',
        'Staff',
        'Total Basic',
        'Total Payable',
        'Paid Amount',
        'Pending',
      ],
      data: sortedKeys.map((campus) {
        final list = groups[campus]!;
        final totalBasic = list.fold<double>(0, (s, i) => s + i.basicSalary);
        final totalPayable = list.fold<double>(0, (s, i) => s + i.totalSalary);
        final paid = list
            .where((s) => s.isPaid)
            .fold<double>(0, (s, i) => s + i.totalSalary);

        return [
          campus,
          list.length.toString(),
          _currencyFormat.format(totalBasic),
          _currencyFormat.format(totalPayable),
          _currencyFormat.format(paid),
          _currencyFormat.format(totalPayable - paid),
        ];
      }).toList(),
    );
  }

  pw.Widget _buildSalaryTable(List<Salary> salaries) {
    return pw.TableHelper.fromTextArray(
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
      ),
      cellStyle: const pw.TextStyle(fontSize: 7),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
        7: pw.Alignment.centerRight,
        8: pw.Alignment.centerRight,
        9: pw.Alignment.center,
      },
      headers: [
        'Name',
        'Campus',
        'Type',
        'Rate',
        'Qty/Hrs/Days',
        'Basic/Gross',
        'Adv',
        'Deduct',
        'Net Pay',
        'Status',
      ],
      data: salaries.map((s) {
        final typeStr = s.salaryType == 'hourly'
            ? 'Hourly'
            : s.salaryType == 'lecture_based'
                ? 'Lecture'
                : 'Monthly';

        String rateStr = '';
        if (s.salaryType == 'hourly') {
          rateStr = 'Rs ${_currencyFormat.format(s.hourlyRate)}/hr';
        } else if (s.salaryType == 'lecture_based') {
          final rate = s.workingDays > 0 ? (s.basicSalary / s.workingDays) : 0.0;
          rateStr = 'Rs ${_currencyFormat.format(rate)}/lec';
        } else {
          rateStr = 'Rs ${_currencyFormat.format(s.basicSalary)}/mo';
        }

        String qtyStr = '';
        if (s.salaryType == 'hourly') {
          qtyStr = '${s.totalHours.toStringAsFixed(1)} hrs';
        } else if (s.salaryType == 'lecture_based') {
          qtyStr = '${s.workingDays.toStringAsFixed(0)} lecs';
        } else {
          qtyStr = 'Abs: ${s.absents.toStringAsFixed(1)}';
        }

        return [
          s.staffName,
          s.campus ?? '-',
          typeStr,
          rateStr,
          qtyStr,
          _currencyFormat.format(s.basicSalary),
          _currencyFormat.format(s.advanceAmount),
          _currencyFormat.format(s.deduction),
          _currencyFormat.format(s.totalSalary),
          s.isPaid ? 'PAID' : 'PENDING',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildSummaryCard(List<Salary> salaries) {
    double totalPayable = 0;
    double totalPaid = 0;
    int paidCount = 0;

    for (var s in salaries) {
      totalPayable += s.totalSalary;
      if (s.isPaid) {
        totalPaid += s.totalSalary;
        paidCount++;
      }
    }

    return pw.Container(
      width: 250,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: primaryColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SUMMARY',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 8),
          _summaryRow('Total Staff', salaries.length.toString()),
          _summaryRow(
            'Total Payable',
            'Rs ${_currencyFormat.format(totalPayable)}',
            isBold: true,
          ),
          pw.Divider(color: PdfColors.grey400),
          _summaryRow(
            'Paid ($paidCount)',
            'Rs ${_currencyFormat.format(totalPaid)}',
            color: PdfColors.green700,
          ),
          _summaryRow(
            'Pending',
            'Rs ${_currencyFormat.format(totalPayable - totalPaid)}',
            color: PdfColors.orange700,
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPayslipContent(Salary salary, String monthName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Payslip Header
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: primaryColor,
            borderRadius: const pw.BorderRadius.vertical(
              top: pw.Radius.circular(12),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PAYSLIP',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '$monthName ${salary.year}',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: salary.isPaid
                      ? PdfColors.green500
                      : PdfColors.orange500,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  salary.isPaid ? 'PAID' : 'UNPAID',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Employee Info
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: lightBg,
            border: pw.Border.all(color: primaryColor),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EMPLOYEE',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    salary.staffName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.Text(
                    salary.campus ?? '',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'PAY DATE',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    salary.paidDate != null
                        ? DateFormat(
                            'dd MMM yyyy',
                          ).format(DateTime.parse(salary.paidDate!))
                        : '-',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 30),

        // Earnings & Deductions
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Earnings
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EARNINGS',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  if (salary.salaryType == 'hourly')
                    _payslipRow(
                      'Hourly Pay (${salary.totalHours.toStringAsFixed(1)} hrs @ Rs ${salary.hourlyRate.toStringAsFixed(0)}/hr)',
                      salary.basicSalary,
                    )
                  else if (salary.salaryType == 'lecture_based')
                    _payslipRow(
                      'Lecture Pay (${salary.workingDays.toStringAsFixed(0)} lecs)',
                      salary.basicSalary,
                    )
                  else
                    _payslipRow('Basic Salary', salary.basicSalary),
                  if (salary.bonus > 0)
                    _payslipRow('Performance Bonus', salary.bonus),
                  pw.Divider(),
                  _payslipRow(
                    'Total Earnings',
                    salary.basicSalary + salary.bonus,
                    isBold: true,
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 30),
            // Deductions
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DEDUCTIONS',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  if (salary.salaryType == 'monthly' && _calcAbsentDeduction(salary) > 0)
                    _payslipRow(
                      'Absents (${salary.absents})',
                      _calcAbsentDeduction(salary),
                    ),
                  if (salary.advanceAmount > 0)
                    _payslipRow('Advance', salary.advanceAmount),
                  if (salary.otherDeductions > 0)
                    _payslipRow('Other Deductions', salary.otherDeductions),
                  if (salary.deduction == 0 && salary.advanceAmount == 0 && salary.otherDeductions == 0)
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text('No Deductions', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
                    ),
                  pw.Divider(),
                  _payslipRow(
                    'Total Deductions',
                    salary.deduction,
                    isBold: true,
                    color: PdfColors.red700,
                  ),
                ],
              ),
            ),
          ],
        ),

        pw.Spacer(),

        // Net Pay
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: primaryColor,
            borderRadius: const pw.BorderRadius.vertical(
              bottom: pw.Radius.circular(12),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'NET PAYABLE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                'Rs ${_currencyFormat.format(salary.totalSalary)}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 40),
      ],
    );
  }

  double _calcAbsentDeduction(Salary s) {
    if (s.salaryType != 'monthly') return 0.0;
    // Absent deduction is the remainder of deduction after advance and other deductions
    final val = s.deduction - s.advanceAmount - s.otherDeductions;
    return val < 0 ? 0.0 : val;
  }

  pw.Widget _payslipRow(
    String label,
    double amount, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            'Rs ${_currencyFormat.format(amount)}',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
