import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../repositories/tax_invoice_repository.dart';
import '../models/tax_invoice_model.dart';
import '../services/pdf_service.dart';
import 'pdf_viewer_screen.dart';

class TaxInvoiceDetailsScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const TaxInvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<TaxInvoiceDetailsScreen> createState() => _TaxInvoiceDetailsScreenState();
}

class _TaxInvoiceDetailsScreenState extends ConsumerState<TaxInvoiceDetailsScreen> {
  TaxInvoiceModel? _invoice;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    try {
      final repo = ref.read(taxInvoiceRepositoryProvider);
      final result = await repo.getTaxInvoiceById(widget.invoiceId);
      setState(() {
        _invoice = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _downloadPdf() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(pdfServiceProvider).printOrSaveTaxInvoicePdf(_invoice!);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _sharePdf() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(pdfServiceProvider).shareTaxInvoicePdf(_invoice!);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $_error')));

    final inv = _invoice!;
    final payment = inv.paymentDetails;

    final mainContent = Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(inv.invoiceNumber ?? 'Invoice Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bill To: ${inv.billTo.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Total Amount: ₹${inv.totalAmount?.toStringAsFixed(2)}'),
                    Text('Payment Status: ${payment?.status ?? "Unpaid"}'),
                    if (payment != null) Text('Pending Amount: ₹${payment.remainingAmount?.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      title: inv.invoiceNumber ?? 'Tax Invoice PDF',
                      pdfBuilder: () => ref.read(pdfServiceProvider).generateTaxInvoicePdf(inv),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('View as PDF'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: _downloadPdf, icon: const Icon(Icons.download), label: const Text('Download'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(onPressed: _sharePdf, icon: const Icon(Icons.share), label: const Text('Share'))),
              ],
            ),
          ],
        ),
      ),
    );
    
    return Stack(
      children: [
        mainContent,
        if (_isActionLoading)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
