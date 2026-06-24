import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/salary.dart';

class AttendanceReportData {
  final String staffName;
  final String campusName;
  final String salaryType;
  final int absents;
  final int lates;
  final int halfLeaves;
  final double totalHours;
  final double totalLectures;

  AttendanceReportData({
    required this.staffName,
    required this.campusName,
    required this.salaryType,
    required this.absents,
    required this.lates,
    required this.halfLeaves,
    required this.totalHours,
    required this.totalLectures,
  });
}

class PdfService {
  final _currencyFormat = NumberFormat('#,##0');

  // Brand Colors (Deep Navy & Electric Cyan theme)
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF060D1F); // Deep Navy
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF0066FF); // Dark Blue
  static const PdfColor accentColor = PdfColor.fromInt(0xFF00C2FF); // Electric Cyan
  static const PdfColor lightBg = PdfColor.fromInt(0xFFF8FAFC); // Slate 50
  static const PdfColor cardBorderColor = PdfColor.fromInt(0xFFE2E8F0); // Slate 200
  static const PdfColor textPrimary = PdfColor.fromInt(0xFF1E293B); // Slate 800
  static const PdfColor textSecondary = PdfColor.fromInt(0xFF64748B); // Slate 500

  Future<Uint8List> generateMonthlyReport(
    List<Salary> salaries,
    int month,
    int year,
    String? campus,
  ) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM').format(DateTime(year, month));
    final reportDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

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
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _buildHeader(
          'Monthly Salary Report',
          '$monthName $year',
          campus ?? 'All Campuses',
          reportDate,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildMonthlySummaryDashboard(salaries),
          pw.SizedBox(height: 20),
          if (campus == null && campusGroups.length > 1) ...[
            _buildSectionTitle('Campus Breakdown'),
            _buildCampusBreakdownTable(campusGroups),
            pw.SizedBox(height: 20),
          ],
          _buildSectionTitle('Staff Salary Details'),
          _buildCustomSalaryTable(salaries),
        ],
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generatePayslip(Salary salary) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM').format(DateTime(salary.year, salary.month));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => _buildPayslipContent(salary, monthName),
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generateAttendanceReport(
    List<AttendanceReportData> data,
    int month,
    int year,
    String campus,
  ) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM').format(DateTime(year, month));
    final reportDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    // Calculate totals
    int totalStaff = data.length;
    int totalAbsents = data.fold<int>(0, (sum, d) => sum + d.absents);
    int totalLates = data.fold<int>(0, (sum, d) => sum + d.lates);
    int totalHalfLeaves = data.fold<int>(0, (sum, d) => sum + d.halfLeaves);
    double totalHours = data.fold<double>(0, (sum, d) => sum + d.totalHours);
    double totalLectures = data.fold<double>(0, (sum, d) => sum + d.totalLectures);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _buildHeader(
          'Monthly Attendance Report',
          '$monthName $year',
          campus,
          reportDate,
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildAttendanceSummaryGrid(
            totalStaff: totalStaff,
            absents: totalAbsents,
            lates: totalLates,
            halfLeaves: totalHalfLeaves,
            hours: totalHours,
            lectures: totalLectures,
          ),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Staff Attendance Details'),
          _buildCustomAttendanceTable(data),
        ],
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
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 32,
                  height: 32,
                  decoration: const pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: primaryColor,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'S',
                    style: pw.TextStyle(
                      color: accentColor,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      children: [
                        pw.Text(
                          subtitle,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: textSecondary,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: const pw.BoxDecoration(
                            color: lightBg,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            campus,
                            style: pw.TextStyle(fontSize: 8, color: primaryColor, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'SALARYSOFT SYSTEM',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Generated: $date',
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 3,
          decoration: const pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [primaryColor, accentColor],
            ),
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(height: 15),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
        pw.Container(height: 0.5, color: cardBorderColor),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Confidential & Proprietary',
              style: pw.TextStyle(fontSize: 7, color: textSecondary, fontStyle: pw.FontStyle.italic),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 7, color: textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8, top: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 10,
            decoration: const pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMonthlySummaryDashboard(List<Salary> salaries) {
    double totalPayable = 0;
    double totalPaid = 0;
    int paidCount = 0;
    int pendingCount = 0;

    for (var s in salaries) {
      totalPayable += s.totalSalary;
      if (s.isPaid) {
        totalPaid += s.totalSalary;
        paidCount++;
      } else {
        pendingCount++;
      }
    }
    double totalPending = totalPayable - totalPaid;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildDashboardCard('Total Staff', salaries.length.toString(), secondaryColor),
        _buildDashboardCard('Total Payable', 'Rs ${_currencyFormat.format(totalPayable)}', primaryColor),
        _buildDashboardCard('Total Paid ($paidCount)', 'Rs ${_currencyFormat.format(totalPaid)}', const PdfColor.fromInt(0xFF2E7D32)),
        _buildDashboardCard('Pending ($pendingCount)', 'Rs ${_currencyFormat.format(totalPending)}', const PdfColor.fromInt(0xFFE65100)),
      ],
    );
  }

  pw.Widget _buildAttendanceSummaryGrid({
    required int totalStaff,
    required int absents,
    required int lates,
    required int halfLeaves,
    required double hours,
    required double lectures,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildDashboardCard('Total Staff', totalStaff.toString(), secondaryColor),
        _buildDashboardCard('Total Absents', absents.toString(), const PdfColor.fromInt(0xFFC62828)),
        _buildDashboardCard('Total Lates', lates.toString(), const PdfColor.fromInt(0xFFE65100)),
        _buildDashboardCard('Half Leaves', halfLeaves.toString(), const PdfColor.fromInt(0xFFF57F17)),
        if (hours > 0)
          _buildDashboardCard('Hours Worked', '${hours.toStringAsFixed(1)} hrs', const PdfColor.fromInt(0xFF6A1B9A)),
        if (lectures > 0)
          _buildDashboardCard('Lectures Conducted', '${lectures.toStringAsFixed(0)} lecs', const PdfColor.fromInt(0xFF00695C)),
      ],
    );
  }

  pw.Widget _buildDashboardCard(String title, String value, PdfColor accentIndicatorColor) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: lightBg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: cardBorderColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 3,
                  height: 10,
                  decoration: pw.BoxDecoration(
                    color: accentIndicatorColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(1.5)),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildCampusBreakdownTable(Map<String, List<Salary>> groups) {
    final sortedKeys = groups.keys.toList()..sort();

    final List<pw.TableRow> rows = [];
    
    // Header Row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: primaryColor,
          borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
        ),
        children: [
          _tableHeaderCell('Campus'),
          _tableHeaderCell('Staff Count'),
          _tableHeaderCell('Total Basic'),
          _tableHeaderCell('Total Payable'),
          _tableHeaderCell('Paid Amount'),
          _tableHeaderCell('Pending'),
        ],
      ),
    );

    // Data Rows
    for (int i = 0; i < sortedKeys.length; i++) {
      final campus = sortedKeys[i];
      final list = groups[campus]!;
      final totalBasic = list.fold<double>(0, (s, item) => s + item.basicSalary);
      final totalPayable = list.fold<double>(0, (s, item) => s + item.totalSalary);
      final paid = list.where((s) => s.isPaid).fold<double>(0, (s, item) => s + item.totalSalary);
      final isEven = i % 2 == 0;

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? lightBg : PdfColors.white,
            border: const pw.Border(bottom: pw.BorderSide(color: cardBorderColor, width: 0.5)),
          ),
          children: [
            _tableCell(campus, isBold: true),
            _tableCell(list.length.toString()),
            _tableCell('Rs ${_currencyFormat.format(totalBasic)}'),
            _tableCell('Rs ${_currencyFormat.format(totalPayable)}', isBold: true),
            _tableCell('Rs ${_currencyFormat.format(paid)}', color: const PdfColor.fromInt(0xFF2E7D32)),
            _tableCell('Rs ${_currencyFormat.format(totalPayable - paid)}', color: const PdfColor.fromInt(0xFFE65100)),
          ],
        ),
      );
    }

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2.0),
        1: const pw.FlexColumnWidth(1.0),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  pw.Widget _buildCustomSalaryTable(List<Salary> salaries) {
    final List<pw.TableRow> rows = [];
    
    // Header Row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: primaryColor,
          borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
        ),
        children: [
          _tableHeaderCell('Name'),
          _tableHeaderCell('Campus'),
          _tableHeaderCell('Type'),
          _tableHeaderCell('Rate'),
          _tableHeaderCell('Qty/Hrs/Days'),
          _tableHeaderCell('Basic/Gross'),
          _tableHeaderCell('Adv/Deduct'),
          _tableHeaderCell('Net Pay'),
          _tableHeaderCell('Status'),
        ],
      ),
    );

    // Data Rows
    for (int i = 0; i < salaries.length; i++) {
      final s = salaries[i];
      final isEven = i % 2 == 0;
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

      final statusVal = s.statusText;

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? lightBg : PdfColors.white,
            border: const pw.Border(bottom: pw.BorderSide(color: cardBorderColor, width: 0.5)),
          ),
          children: [
            _tableCell(s.staffName, isBold: true),
            _tableCell(s.campus ?? '-'),
            _tableCell(typeStr),
            _tableCell(rateStr),
            _tableCell(qtyStr),
            _tableCell('Rs ${_currencyFormat.format(s.basicSalary)}'),
            _tableCell('Rs ${_currencyFormat.format(s.advanceAmount + s.deduction)}'),
            _tableCell('Rs ${_currencyFormat.format(s.totalSalary)}', isBold: true, color: secondaryColor),
            _statusBadgeCell(statusVal),
          ],
        ),
      );
    }

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2.0),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.0),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(1.2),
        7: const pw.FlexColumnWidth(1.2),
        8: const pw.FlexColumnWidth(1.2),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  pw.Widget _buildCustomAttendanceTable(List<AttendanceReportData> data) {
    final List<pw.TableRow> rows = [];
    
    // Header Row
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: primaryColor,
          borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
        ),
        children: [
          _tableHeaderCell('Name'),
          _tableHeaderCell('Campus'),
          _tableHeaderCell('Salary Type'),
          _tableHeaderCell('Absents'),
          _tableHeaderCell('Lates'),
          _tableHeaderCell('Half Leaves'),
          _tableHeaderCell('Hours Worked'),
          _tableHeaderCell('Lectures'),
        ],
      ),
    );

    // Data Rows
    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final isEven = i % 2 == 0;

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? lightBg : PdfColors.white,
            border: const pw.Border(bottom: pw.BorderSide(color: cardBorderColor, width: 0.5)),
          ),
          children: [
            _tableCell(d.staffName, isBold: true),
            _tableCell(d.campusName),
            _tableCell(d.salaryType),
            _tableCell(d.absents > 0 ? d.absents.toString() : '-', color: d.absents > 0 ? const PdfColor.fromInt(0xFFC62828) : null),
            _tableCell(d.lates > 0 ? d.lates.toString() : '-', color: d.lates > 0 ? const PdfColor.fromInt(0xFFE65100) : null),
            _tableCell(d.halfLeaves > 0 ? d.halfLeaves.toString() : '-', color: d.halfLeaves > 0 ? const PdfColor.fromInt(0xFFF57F17) : null),
            _tableCell(d.salaryType == 'Hourly' ? '${d.totalHours.toStringAsFixed(1)} hrs' : '-'),
            _tableCell(d.salaryType == 'Lecture' ? '${d.totalLectures.toStringAsFixed(0)} lecs' : '-'),
          ],
        ),
      );
    }

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2.0),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(1.0),
        5: const pw.FlexColumnWidth(1.0),
        6: const pw.FlexColumnWidth(1.3),
        7: const pw.FlexColumnWidth(1.3),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  static pw.Widget _statusBadgeCell(String status) {
    PdfColor bgColor;
    PdfColor textColor;

    if (status == 'Paid') {
      bgColor = const PdfColor.fromInt(0xFFE8F5E9);
      textColor = const PdfColor.fromInt(0xFF2E7D32);
    } else if (status == 'Partial Paid') {
      bgColor = const PdfColor.fromInt(0xFFE3F2FD);
      textColor = const PdfColor.fromInt(0xFF1565C0);
    } else {
      bgColor = const PdfColor.fromInt(0xFFFFF3E0);
      textColor = const PdfColor.fromInt(0xFFE65100);
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        alignment: pw.Alignment.center,
        child: pw.Text(
          status.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          color: color ?? textPrimary,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildPayslipContent(Salary salary, String monthName) {
    final headerGradient = pw.BoxDecoration(
      gradient: const pw.LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: pw.Alignment.topLeft,
        end: pw.Alignment.bottomRight,
      ),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Top Header Gradient
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: headerGradient,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 32,
                    height: 32,
                    decoration: const pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: accentColor,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'S',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SALARYSOFT',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.Text(
                        'Enterprise Pay Solutions',
                        style: const pw.TextStyle(
                          color: PdfColors.grey300,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'PAYSLIP',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.Text(
                    '$monthName ${salary.year}',
                    style: pw.TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 15),

        // Employee Info Card Grid
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: lightBg,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: cardBorderColor, width: 0.5),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _infoBlock('EMPLOYEE NAME', salary.staffName, isBold: true),
                  _infoBlock('CAMPUS / BRANCH', salary.campus ?? '-', isBold: true),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(height: 0.5, color: cardBorderColor),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _infoBlock('SALARY TYPE', salary.salaryType.toUpperCase()),
                  _infoBlock('PAYMENT STATUS', salary.statusText.toUpperCase(), isStatus: true),
                ],
              ),
              if (salary.paidDate != null) ...[
                pw.SizedBox(height: 10),
                pw.Container(height: 0.5, color: cardBorderColor),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _infoBlock('PAYMENT DATE', DateFormat('dd MMM yyyy').format(DateTime.parse(salary.paidDate!))),
                    _infoBlock('TRANSACTION STATUS', 'SUCCESS', color: const PdfColor.fromInt(0xFF2E7D32)),
                  ],
                ),
              ],
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Earnings and Deductions Row
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Earnings Panel
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: cardBorderColor, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EARNINGS & ALLOWANCES',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 10),
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
                    pw.Divider(color: cardBorderColor, thickness: 0.5),
                    _payslipRow(
                      'Gross Earnings',
                      salary.basicSalary + salary.bonus,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 15),
            // Deductions Panel
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: cardBorderColor, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DEDUCTIONS & ADJUSTMENTS',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFFC62828),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    if (salary.salaryType == 'monthly' && _calcAbsentDeduction(salary) > 0)
                      _payslipRow(
                        'Absent Deductions (${salary.absents} days)',
                        _calcAbsentDeduction(salary),
                        color: const PdfColor.fromInt(0xFFC62828),
                      ),
                    if (salary.advanceAmount > 0)
                      _payslipRow(
                        'Salary Advance Recovery',
                        salary.advanceAmount,
                        color: const PdfColor.fromInt(0xFFC62828),
                      ),
                    if (salary.otherDeductions > 0)
                      _payslipRow(
                        'Other Deductions',
                        salary.otherDeductions,
                        color: const PdfColor.fromInt(0xFFC62828),
                      ),
                    if (_calcAbsentDeduction(salary) == 0 && salary.advanceAmount == 0 && salary.otherDeductions == 0)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 10),
                        child: pw.Text(
                          'No Deductions recorded for this period.',
                          style: pw.TextStyle(fontSize: 8, color: textSecondary, fontStyle: pw.FontStyle.italic),
                        ),
                      ),
                    pw.Divider(color: cardBorderColor, thickness: 0.5),
                    _payslipRow(
                      'Total Deductions',
                      salary.deduction,
                      isBold: true,
                      color: const PdfColor.fromInt(0xFFC62828),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 20),

        // Net Salary Banner
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: const pw.BoxDecoration(
            color: primaryColor,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'NET PAYABLE / AMOUNT PAID',
                    style: pw.TextStyle(
                      color: accentColor,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                      letterSpacing: 0.5,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Net payable salary for the billing cycle.',
                    style: const pw.TextStyle(
                      color: PdfColors.grey300,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Rs ${_currencyFormat.format(salary.totalSalary)}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (salary.remainingAmount > 0)
                    pw.Text(
                      'Pending: Rs ${_currencyFormat.format(salary.remainingAmount)}',
                      style: pw.TextStyle(
                        color: PdfColors.amber300,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        pw.Spacer(),

        // Signature section
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 120, height: 0.5, color: textSecondary),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Employee Signature',
                  style: pw.TextStyle(fontSize: 8, color: textSecondary),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(width: 120, height: 0.5, color: textSecondary),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Authorized Signatory',
                  style: pw.TextStyle(fontSize: 8, color: textSecondary),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 10),
      ],
    );
  }

  double _calcAbsentDeduction(Salary s) {
    if (s.salaryType != 'monthly') return 0.0;
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
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: textPrimary)),
          pw.Text(
            'Rs ${_currencyFormat.format(amount)}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _infoBlock(String label, String value, {bool isBold = false, bool isStatus = false, PdfColor? color}) {
    pw.Widget valueWidget;
    if (isStatus) {
      PdfColor bgColor;
      PdfColor txtColor;
      if (value.toLowerCase() == 'paid') {
        bgColor = const PdfColor.fromInt(0xFFE8F5E9);
        txtColor = const PdfColor.fromInt(0xFF2E7D32);
      } else if (value.toLowerCase() == 'partial paid') {
        bgColor = const PdfColor.fromInt(0xFFE3F2FD);
        txtColor = const PdfColor.fromInt(0xFF1565C0);
      } else {
        bgColor = const PdfColor.fromInt(0xFFFFF3E0);
        txtColor = const PdfColor.fromInt(0xFFE65100);
      }
      valueWidget = pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: txtColor,
          ),
        ),
      );
    } else {
      valueWidget = pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? textPrimary,
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: textSecondary,
          ),
        ),
        pw.SizedBox(height: 3),
        valueWidget,
      ],
    );
  }
}
