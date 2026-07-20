import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../models/estimate_model.dart';
import '../repositories/estimate_repository.dart';
import '../providers/estimates_provider.dart';
import '../services/pdf_service.dart';
import 'pdf_viewer_screen.dart';

class EstimateDetailsScreen extends ConsumerStatefulWidget {
  final String estimateId;

  const EstimateDetailsScreen({
    super.key,
    required this.estimateId,
  });

  @override
  ConsumerState<EstimateDetailsScreen> createState() => _EstimateDetailsScreenState();
}

class _EstimateDetailsScreenState extends ConsumerState<EstimateDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EstimateModel? _estimate;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEstimate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEstimate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(estimateRepositoryProvider);
      final estimate = await repo.getEstimateById(widget.estimateId);
      setState(() {
        _estimate = estimate;
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
    if (_estimate == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...'), duration: Duration(seconds: 1)),
    );
    try {
      final pdfService = ref.read(pdfServiceProvider);
      await pdfService.printOrSaveEstimatePdf(_estimate!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _sharePdf() async {
    if (_estimate == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing PDF for sharing...'), duration: Duration(seconds: 1)),
    );
    try {
      final pdfService = ref.read(pdfServiceProvider);
      await pdfService.shareEstimatePdf(_estimate!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _viewAsPdf() {
    if (_estimate == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          title: _estimate!.estimateNumber ?? 'Estimate PDF',
          pdfBuilder: () {
            final pdfService = ref.read(pdfServiceProvider);
            return pdfService.generateEstimatePdf(_estimate!);
          },
        ),
      ),
    );
  }

  void _deleteEstimate() async {
    if (_estimate == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Estimate'),
        content: const Text('Are you sure you want to delete this estimate? This action cannot be undone.'),
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
        const SnackBar(content: Text('Deleting estimate...')),
      );
      try {
        await ref.read(estimateRepositoryProvider).deleteEstimate(widget.estimateId);
        ref.read(estimatesProvider.notifier).refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estimate deleted successfully.')),
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

  void _convertToInvoice() async {
    if (_estimate == null) return;
    context.push('/create-tax-invoice', extra: _estimate);
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
                  onPressed: _loadEstimate,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final estimate = _estimate!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(estimate.estimateNumber ?? 'Estimate Details'),
            Text(
              estimate.estimateFor.customerName,
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
              if (value == 'convert') _convertToInvoice();
              if (value == 'delete') _deleteEstimate();
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
              if (estimate.status != 'converted') ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'convert',
                  child: Row(
                    children: [
                      Icon(Icons.autorenew_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Convert to Tax Invoice', style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete Estimate', style: TextStyle(color: AppColors.error)),
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
                _buildCommercialTab(estimate),
                _buildItemsTab(estimate),
                _buildTermsTab(estimate),
                _buildSignaturesTab(estimate),
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

  Widget _buildCommercialTab(EstimateModel estimate) {
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
                        'Estimate',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (estimate.status == 'converted' ? AppColors.success : AppColors.secondary).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estimate.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: estimate.status == 'converted' ? AppColors.success : AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Estimate Number', estimate.estimateNumber ?? '-'),
                  _buildDetailRow('Date', DateFormat('dd-MM-yyyy').format(estimate.estimateDate)),
                  _buildDetailRow('Place of Supply', estimate.placeOfSupply ?? '36-Telangana'),
                  _buildDetailRow('Amount in Words', estimate.amountInWords ?? 'Rupees Only'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Customer Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimate For', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Divider(height: 20),
                  _buildDetailRow('Name', estimate.estimateFor.customerName),
                  _buildDetailRow('Address', estimate.estimateFor.address),
                  _buildDetailRow('Contact No.', estimate.estimateFor.contactNumber),
                  if (estimate.estimateFor.gstinNumber != null && estimate.estimateFor.gstinNumber!.isNotEmpty)
                    _buildDetailRow('GSTIN', estimate.estimateFor.gstinNumber!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Totals Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Totals Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Divider(height: 20),
                  _buildDetailRow('Sub Total', '₹${estimate.subtotal?.toStringAsFixed(2) ?? '0.00'}'),
                  if ((estimate.totalTax ?? 0) > 0)
                    _buildDetailRow('GST Amount', '₹${estimate.totalTax?.toStringAsFixed(2) ?? '0.00'}'),
                  const Divider(),
                  _buildDetailRow(
                    'Total Amount',
                    '₹${estimate.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                    isBold: true,
                    valueColor: AppColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTab(EstimateModel estimate) {
    if (estimate.items.isEmpty) {
      return const Center(child: Text('No items found.'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: estimate.items.length,
      itemBuilder: (context, index) {
        final item = estimate.items[index];
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
                            'Quantity: ${item.quantity} ${item.unit} | Rate: ₹${item.pricePerUnit.toStringAsFixed(2)}',
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
                        if ((item.sgst ?? 0) + (item.cgst ?? 0) > 0)
                          Text(
                            'GST: ${item.gstPercentage}%',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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

  Widget _buildTermsTab(EstimateModel estimate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTermsCard('Terms & Conditions', estimate.termsAndConditions ?? 'Thank you for doing business with us.\n*100% advance is mandatory'),
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

  Widget _buildSignaturesTab(EstimateModel estimate) {
    final qrBase64 = estimate.paymentData?.qrBase64;
    
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
                    if (estimate.paymentData?.clickToPayLink != null)
                      Text(
                        'Click to Pay link is available in the PDF.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Signature card
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
                    child: estimate.technicianSignatureUrl != null && estimate.technicianSignatureUrl!.isNotEmpty
                        ? Image.network(estimate.technicianSignatureUrl!, fit: BoxFit.contain)
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
