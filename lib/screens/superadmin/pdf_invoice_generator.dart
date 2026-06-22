import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/invoice.dart';
import '../../models/client.dart';

class PdfInvoiceGenerator {
  static Future<void> generateAndPrint(Invoice invoice, Client client) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(invoice),
              pw.SizedBox(height: 40),
              _buildClientInfo(client),
              pw.SizedBox(height: 40),
              _buildInvoiceDetails(invoice, client),
              pw.SizedBox(height: 40),
              _buildTotals(invoice, client),
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  static pw.Widget _buildHeader(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'SALARY SOFT',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.deepPurple,
              ),
            ),
            pw.Text('SaaS Billing Department'),
            pw.Text('support@salarysoft.com'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              '#${invoice.invoiceNumber}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Date: ${DateFormat('MMM dd, yyyy').format(invoice.issueDate)}',
            ),
            pw.Text(
              'Due Date: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate)}',
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildClientInfo(Client client) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BILL TO:',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          client.instituteName,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
        ),
        pw.Text('Attn: ${client.ownerName}'),
        if (client.address.isNotEmpty) pw.Text(client.address),
        pw.Text('Phone: ${client.phone}'),
        if (client.email.isNotEmpty) pw.Text('Email: ${client.email}'),
      ],
    );
  }

  static pw.Widget _buildInvoiceDetails(Invoice invoice, Client client) {
    return pw.TableHelper.fromTextArray(
      headers: ['Description', 'Billing Period', 'Amount'],
      data: [
        [
          'SalarySoft Subscription (${invoice.status.toUpperCase()})',
          '${DateFormat('MMM dd, yyyy').format(invoice.issueDate)} - ${DateFormat('MMM dd, yyyy').format(invoice.dueDate)}',
          '${client.currency} ${invoice.amount.toStringAsFixed(2)}',
        ],
      ],
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
      cellHeight: 40,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildTotals(Invoice invoice, Client client) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Subtotal:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '${client.currency} ${invoice.amount.toStringAsFixed(2)}',
                  ),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Due:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  pw.Text(
                    '${client.currency} ${invoice.amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepPurple,
          ),
        ),
        pw.Text(
          'Please make payment by the due date to avoid service interruption.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }
}
