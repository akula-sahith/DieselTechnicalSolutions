import 'dart:convert';
import '../core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/estimate_repository.dart';
import '../models/estimate_model.dart';
import '../providers/tax_invoice_wizard_provider.dart';
import '../services/pdf_service.dart';
import 'package:go_router/go_router.dart';
import 'pdf_viewer_screen.dart';

class EstimateDetailsScreen extends ConsumerStatefulWidget {
  final String estimateId;
  const EstimateDetailsScreen({super.key, required this.estimateId});

  @override
  ConsumerState<EstimateDetailsScreen> createState() => _EstimateDetailsScreenState();
}

class _EstimateDetailsScreenState extends ConsumerState<EstimateDetailsScreen> {
  EstimateModel? _estimate;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEstimate();
  }

  Future<void> _fetchEstimate() async {
    try {
      final repo = ref.read(estimateRepositoryProvider);
      final result = await repo.getEstimateById(widget.estimateId);
      setState(() {
        _estimate = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _convertToInvoice() async {
    context.push('/create-tax-invoice', extra: _estimate);
  }

  void _downloadPdf() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(pdfServiceProvider).printOrSaveEstimatePdf(_estimate!);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _sharePdf() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(pdfServiceProvider).shareEstimatePdf(_estimate!);
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

    final est = _estimate!;
    final qrBase64 = est.paymentData?.qrBase64;

    final mainContent = Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(est.estimateNumber ?? 'Estimate Details')),
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
                    Text('Customer: ${est.estimateFor.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Total Amount: ₹${est.totalAmount?.toStringAsFixed(2)}'),
                    Text('Status: ${est.status.toUpperCase()}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (qrBase64 != null) ...[
              const Text('Payment QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Center(
                child: Image.memory(
                  base64Decode(qrBase64.split(',').last),
                  height: 200,
                  width: 200,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 100),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (est.status != 'converted')
              ElevatedButton(
                onPressed: _convertToInvoice,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Convert to Tax Invoice', style: TextStyle(color: Colors.white)),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      title: est.estimateNumber ?? 'Estimate PDF',
                      pdfBuilder: () => ref.read(pdfServiceProvider).generateEstimatePdf(est),
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
