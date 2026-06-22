import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/invoice.dart';
import '../../models/client.dart';
import '../../services/invoice_service.dart';
import '../../services/subscription_service.dart';
import 'pdf_invoice_generator.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  List<Invoice> _invoices = [];
  Map<String, Client> _clientsMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final invoices = await _invoiceService.getAllInvoices();
      final clients = await _subscriptionService.getClients();

      final Map<String, Client> cMap = {};
      for (var c in clients) {
        cMap[c.id] = c;
      }

      setState(() {
        _invoices = invoices;
        _clientsMap = cMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePdf(Invoice invoice) async {
    final client = _clientsMap[invoice.clientId];
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client data not found for this invoice.'),
        ),
      );
      return;
    }

    try {
      await PdfInvoiceGenerator.generateAndPrint(invoice, client);
    } catch (e) {
      debugPrint('PDF Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'overdue':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
          ? const Center(child: Text('No invoices found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final invoice = _invoices[index];
                final clientName =
                    _clientsMap[invoice.clientId]?.instituteName ??
                    'Unknown Client';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.deepPurple,
                      ),
                    ),
                    title: Text(
                      'Invoice #${invoice.invoiceNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clientName),
                        Text(
                          'Due: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate)}',
                        ),
                        Text(
                          '${_clientsMap[invoice.clientId]?.currency ?? "PKR"} ${invoice.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(
                          label: Text(
                            invoice.status.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: _getStatusColor(invoice.status),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _generatePdf(invoice),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
