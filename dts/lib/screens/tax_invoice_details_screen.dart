import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/tax_invoice_model.dart';
import '../repositories/tax_invoice_repository.dart';
import '../services/pdf_service.dart';
import '../providers/dashboard_stats_provider.dart';
import '../providers/tax_invoices_provider.dart';
import 'pdf_viewer_screen.dart';

class TaxInvoiceDetailsScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  final TaxInvoiceModel? initialInvoice;

  const TaxInvoiceDetailsScreen({
    super.key,
    required this.invoiceId,
    this.initialInvoice,
  });

  @override
  ConsumerState<TaxInvoiceDetailsScreen> createState() => _TaxInvoiceDetailsScreenState();
}

class _TaxInvoiceDetailsScreenState extends ConsumerState<TaxInvoiceDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TaxInvoiceModel? _invoice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.initialInvoice != null) {
      _invoice = widget.initialInvoice;
      _isLoading = false;
    } else {
      _loadInvoice();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(taxInvoiceRepositoryProvider);
      final invoice = await repo.getTaxInvoiceById(widget.invoiceId);
      setState(() {
        _invoice = invoice;
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
    if (_invoice == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...'), duration: Duration(seconds: 1)),
    );
    try {
      final pdfService = ref.read(pdfServiceProvider);
      await pdfService.printOrSaveTaxInvoicePdf(_invoice!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _sharePdf() async {
    if (_invoice == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing PDF for sharing...'), duration: Duration(seconds: 1)),
    );
    try {
      final pdfService = ref.read(pdfServiceProvider);
      await pdfService.shareTaxInvoicePdf(_invoice!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _viewAsPdf() {
    if (_invoice == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          title: _invoice!.invoiceNumber ?? 'Tax Invoice PDF',
          pdfBuilder: () {
            final pdfService = ref.read(pdfServiceProvider);
            return pdfService.generateTaxInvoicePdf(_invoice!);
          },
        ),
      ),
    );
  }

  void _deleteInvoice() async {
    if (_invoice == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tax Invoice'),
        content: const Text('Are you sure you want to delete this invoice? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting tax invoice...')),
      );
      try {
        await ref.read(taxInvoiceRepositoryProvider).deleteTaxInvoice(widget.invoiceId);
        // Refresh provider logic can be added if a provider exists
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tax Invoice deleted successfully.')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInvoice,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final invoice = _invoice!;
    final payment = invoice.paymentDetails;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invoice.invoiceNumber ?? 'Invoice Details'),
            Text(
              invoice.billTo.customerName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: _viewAsPdf,
            tooltip: 'View as PDF',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'download') _downloadPdf();
              if (value == 'share') _sharePdf();
              if (value == 'delete') _deleteInvoice();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Download PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_rounded, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Share PDF'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete Invoice', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Commercial'),
            Tab(text: 'Items'),
            Tab(text: 'Terms'),
            Tab(text: 'Sign-off'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCommercialTab(invoice),
                _buildItemsTab(invoice),
                _buildTermsTab(invoice),
                _buildSignaturesTab(invoice),
              ],
            ),
          ),
          
          // Action Buttons Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sharePdf,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share PDF'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadPdf,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download PDF'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentDialog(TaxInvoiceModel invoice) {
    final amountCtrl = TextEditingController();
    final txIdCtrl = TextEditingController();
    String method = 'Bank Transfer';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹) *',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method *',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'UPI / GPay / PhonePe', child: Text('UPI / GPay / PhonePe')),
                    DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                    DropdownMenuItem(value: 'Others', child: Text('Others')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => method = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: txIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Transaction ID / Reference',
                    prefixIcon: Icon(Icons.receipt),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(DateFormat('dd-MM-yyyy').format(selectedDate)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive amount'), backgroundColor: AppColors.error),
                  );
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recording payment...')),
                );
                try {
                  final repo = ref.read(taxInvoiceRepositoryProvider);
                  final updatedInvoice = await repo.recordPayment(
                    id: invoice.id!,
                    amount: amt,
                    method: method,
                    transactionId: txIdCtrl.text.trim(),
                    date: selectedDate,
                  );
                  
                  ref.read(dashboardStatsProvider.notifier).fetchStats();
                  ref.read(taxInvoicesProvider.notifier).refresh();
                  if (mounted) {
                    setState(() {
                      _invoice = updatedInvoice;
                    });
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment recorded successfully!'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to record payment: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommercialTab(TaxInvoiceModel invoice) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Basic Info
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tax Invoice',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(invoice.paymentStatus).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          invoice.paymentStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(invoice.paymentStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Invoice Number', invoice.invoiceNumber ?? '-'),
                  _buildDetailRow('Date', DateFormat('dd-MM-yyyy').format(invoice.invoiceDate)),
                  _buildDetailRow('Place of Supply', invoice.placeOfSupply ?? '36-Telangana'),
                  _buildDetailRow('Amount in Words', invoice.amountInWords ?? 'Rupees Only'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bill To Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bill To', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Divider(height: 20),
                  _buildDetailRow('Name', invoice.billTo.customerName),
                  _buildDetailRow('Address', invoice.billTo.address),
                  _buildDetailRow('Contact No.', invoice.billTo.contactNumber),
                  if (invoice.billTo.gstinNumber != null && invoice.billTo.gstinNumber!.isNotEmpty)
                    _buildDetailRow('GSTIN', invoice.billTo.gstinNumber!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Transportation Details Card
          if (invoice.transportationDetails != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transportation Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Divider(height: 20),
                    if (invoice.transportationDetails!.vehicleNumber != null)
                      _buildDetailRow('Vehicle No.', invoice.transportationDetails!.vehicleNumber!),
                    if (invoice.transportationDetails!.transportName != null)
                      _buildDetailRow('Transport Name', invoice.transportationDetails!.transportName!),
                    if (invoice.transportationDetails!.lrNumber != null)
                      _buildDetailRow('LR No.', invoice.transportationDetails!.lrNumber!),
                    if (invoice.transportationDetails!.dispatchDetails != null)
                      _buildDetailRow('Dispatch Through', invoice.transportationDetails!.dispatchDetails!),
                    if (invoice.transportationDetails!.deliveryDetails != null)
                      _buildDetailRow('Destination', invoice.transportationDetails!.deliveryDetails!),
                  ],
                ),
              ),
            ),
          if (invoice.transportationDetails != null) const SizedBox(height: 16),

          // Totals Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Divider(height: 20),
                  _buildDetailRow('Sub Total', '₹${invoice.subtotal?.toStringAsFixed(2) ?? '0.00'}'),
                  if (invoice.discountType != 'none')
                    _buildDetailRow(
                      'Discount (${invoice.discountType})',
                      '- ₹${invoice.discountAmount?.toStringAsFixed(2) ?? '0.00'}',
                      valueColor: AppColors.success,
                    ),
                  if (invoice.discountType != 'none')
                    _buildDetailRow('Taxable Amount', '₹${invoice.taxableAmount?.toStringAsFixed(2) ?? '0.00'}'),
                  _buildDetailRow(
                    'Total Tax (GST)',
                    '₹${((invoice.totalTax != null && invoice.totalTax! > 0) ? invoice.totalTax! : invoice.items.fold<double>(0.0, (s, e) => s + ((e.sgst ?? 0.0) + (e.cgst ?? 0.0)))).toStringAsFixed(2)}',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Total Amount',
                    '₹${invoice.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                    isBold: true,
                    valueColor: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Payments & Tracking Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment History',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(invoice.paymentStatus).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          invoice.paymentStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(invoice.paymentStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildDetailRow('Received Amount', '₹${invoice.receivedAmount.toStringAsFixed(2)}', valueColor: AppColors.success),
                  _buildDetailRow('Outstanding Balance', '₹${invoice.outstandingAmount.toStringAsFixed(2)}', valueColor: AppColors.error),
                  const SizedBox(height: 12),
                  if (invoice.payments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('No payments recorded yet.', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                    )
                  else ...[
                    const Text('Past Payments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: invoice.payments.length,
                      itemBuilder: (context, idx) {
                        final p = invoice.payments[idx];
                        final pDate = DateFormat('dd-MM-yyyy').format(p.paymentDate);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('₹${p.amountReceived.toStringAsFixed(2)} - ${p.paymentMethod ?? 'Others'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (p.referenceNumber != null && p.referenceNumber!.isNotEmpty)
                                    Text('TxID: ${p.referenceNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                              Text(pDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showRecordPaymentDialog(invoice),
                      icon: const Icon(Icons.add),
                      label: const Text('Record Payment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTab(TaxInvoiceModel invoice) {
    if (invoice.items.isEmpty) {
      return const Center(child: Text('No items found.'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoice.items.length,
      itemBuilder: (context, index) {
        final item = invoice.items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      radius: 14,
                      child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Quantity: ${item.quantity} | Rate: ₹${item.pricePerUnit.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          if (item.hsnSac != null && item.hsnSac!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'HSN/SAC: ${item.hsnSac}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${item.amount?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        Builder(
                          builder: (context) {
                            final itemTax = ((item.sgst ?? 0) + (item.cgst ?? 0)) > 0
                                ? ((item.sgst ?? 0) + (item.cgst ?? 0))
                                : (item.taxApplicable ? (item.pricePerUnit * item.quantity * (item.gstPercentage / 100)) : 0.0);
                            return Text(
                              'GST (${item.taxApplicable ? item.gstPercentage : 0}%): ₹${itemTax.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsTab(TaxInvoiceModel invoice) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTermsCard('Terms & Conditions', invoice.termsAndConditions ?? 'Thank you for doing business with us.\n* You want a tax bill that will be 18% higher.'),
        ],
      ),
    );
  }

  Widget _buildTermsCard(String title, String content) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const Divider(height: 20),
            Text(
              content,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignaturesTab(TaxInvoiceModel invoice) {
    final qrBase64 = invoice.paymentData?.qrBase64;
    final customerSig = invoice.customerSignatureUrl;
    final techSig = invoice.technicianSignatureUrl;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payment QR Code Card
          if (qrBase64 != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Payment QR Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Divider(height: 20),
                    Image.memory(
                      base64Decode(qrBase64.split(',').last),
                      height: 150,
                      width: 150,
                      errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50),
                    ),
                    const SizedBox(height: 16),
                    if (invoice.paymentData?.clickToPayLink != null)
                      Text(
                        'Click to Pay link is available in the PDF.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Customer signature card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer Signature', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Divider(height: 20),
                  Text('Signed by: ${invoice.billTo.customerName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: customerSig != null && customerSig.isNotEmpty
                        ? Image.network(customerSig, fit: BoxFit.contain)
                        : const Center(child: Text('No Customer Signature', style: TextStyle(color: AppColors.textLight))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Technician signature card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Authorized Signatory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Divider(height: 20),
                  const Text('For: Diesel Technical Solutions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: techSig != null && techSig.isNotEmpty
                        ? Image.network(techSig, fit: BoxFit.contain)
                        : const Center(child: Text('No Signature', style: TextStyle(color: AppColors.textLight))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'partially paid':
        return AppColors.warning;
      case 'unpaid':
      default:
        return AppColors.error;
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
