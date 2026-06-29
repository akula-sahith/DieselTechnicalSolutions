import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/agreement_model.dart';
import '../repositories/agreement_repository.dart';
import '../services/pdf_service.dart';

class AgreementDetailsScreen extends ConsumerStatefulWidget {
  final String agreementId;

  const AgreementDetailsScreen({
    super.key,
    required this.agreementId,
  });

  @override
  ConsumerState<AgreementDetailsScreen> createState() => _AgreementDetailsScreenState();
}

class _AgreementDetailsScreenState extends ConsumerState<AgreementDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AgreementModel? _agreement;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAgreement();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAgreement() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(agreementRepositoryProvider);
      final agreement = await repo.getAgreementById(widget.agreementId);
      setState(() {
        _agreement = agreement;
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
    if (_agreement == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...'), duration: Duration(seconds: 1)),
    );
    try {
      final pdfService = ref.read(pdfServiceProvider);
      await pdfService.printOrSaveAgreementPdf(_agreement!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _sharePdf() async {
    if (_agreement == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing PDF for sharing...'), duration: Duration(seconds: 1)),
    );
    try {
      final pdfService = ref.read(pdfServiceProvider);
      await pdfService.shareAgreementPdf(_agreement!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: $e'), backgroundColor: AppColors.error),
      );
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
                  onPressed: _loadAgreement,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final agreement = _agreement!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(agreement.offerNumber ?? 'Details'),
            Text(
              agreement.customerName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _downloadPdf,
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
            tooltip: 'Share PDF',
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCommercialTab(agreement),
          _buildItemsTab(agreement),
          _buildTermsTab(agreement),
          _buildSignaturesTab(agreement),
        ],
      ),
    );
  }

  Widget _buildCommercialTab(AgreementModel agreement) {
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
                      Text(
                        agreement.documentType,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (agreement.documentType == 'Agreement' ? AppColors.success : AppColors.secondary).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          agreement.documentType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: agreement.documentType == 'Agreement' ? AppColors.success : AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Offer Number', agreement.offerNumber ?? '-'),
                  _buildDetailRow('Issue Date', DateFormat('dd-MM-yyyy').format(agreement.date)),
                  _buildDetailRow('Amount in Words', agreement.amountInWords ?? 'Rupees Only'),
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
                  const Text('Customer Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Divider(height: 20),
                  _buildDetailRow('Name', agreement.customerName),
                  _buildDetailRow('Address', agreement.completeAddress),
                  _buildDetailRow('Contact Person', agreement.contactPerson),
                  _buildDetailRow('Mobile Number', agreement.mobileNumber),
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
                  _buildDetailRow('Total Before GST', '₹${agreement.totalBeforeGST.toStringAsFixed(2)}'),
                  _buildDetailRow(
                    'GST (${agreement.gstRequired ? agreement.gstPercentage.toStringAsFixed(1) : 0.0}%)',
                    '₹${agreement.gstAmount.toStringAsFixed(2)}',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Grand Total',
                    '₹${agreement.grandTotal.toStringAsFixed(2)}',
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

  Widget _buildItemsTab(AgreementModel agreement) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agreement.descriptionItems.length,
      itemBuilder: (context, index) {
        final item = agreement.descriptionItems[index];
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
                            item.description,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Quantity: ${item.quantity} | Rate: ₹${item.rate.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${item.subTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
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

  Widget _buildTermsTab(AgreementModel agreement) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTermsCard('Terms & Conditions', agreement.termsAndConditions ?? 'All services are subject to the agreed AMC scope, scheduled maintenance, and site accessibility.'),
          const SizedBox(height: 16),
          _buildTermsCard('Payment Terms', agreement.paymentTerms ?? 'Payment is due within 15 days from the date of invoice.'),
          const SizedBox(height: 16),
          _buildTermsCard('Offer Validity', agreement.offerValidity ?? 'This offer is valid for 15 days from the date of issue.'),
          if (agreement.notes != null && agreement.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTermsCard('Notes', agreement.notes!),
          ],
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

  Widget _buildSignaturesTab(AgreementModel agreement) {
    final signatureUrl = agreement.customerSignatureUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  Text('Signed by: ${agreement.contactPerson}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('Signed on: ${DateFormat('dd-MM-yyyy').format(agreement.date)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: signatureUrl != null && signatureUrl.isNotEmpty
                        ? Image.network(signatureUrl, fit: BoxFit.contain)
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
                  const Text('Technician Signature (Representative)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const Divider(height: 20),
                  const Text('Signed by: Siva', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('Signed on: ${DateFormat('dd-MM-yyyy').format(agreement.date)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: agreement.technicianSignatureUrl.isNotEmpty
                        ? Image.network(agreement.technicianSignatureUrl, fit: BoxFit.contain)
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
