import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/reports_provider.dart';
import '../repositories/report_repository.dart';
import '../models/report_model.dart';
import '../services/pdf_service.dart';

class SuccessScreen extends ConsumerStatefulWidget {
  final String reportId;

  const SuccessScreen({
    super.key,
    required this.reportId,
  });

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen> {
  ReportModel? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final repo = ref.read(reportRepositoryProvider);
      final report = await repo.getReportById(widget.reportId);
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback: try to see if we can find it in standard reports
      final reports = ref.read(reportsProvider).reports;
      final found = reports.firstWhere(
        (r) => r.id == widget.reportId,
        orElse: () => throw Exception('Report not found'),
      );
      setState(() {
        _report = found;
        _isLoading = false;
      });
    }
  }

  void _downloadPdf() async {
    if (_report == null) return;
    try {
      final pdfService = ref.read(pdfServiceProvider);
      await pdfService.printOrSavePdf(_report!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _sharePdf() async {
    if (_report == null) return;
    try {
      final pdfService = ref.read(pdfServiceProvider);
      await pdfService.sharePdf(_report!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('dd MMMM yyyy, hh:mm a').format(_report?.createdAt ?? DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    
                    // Success Checkmark
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 96,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Title
                    const Text(
                      'Report Saved Successfully!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Job Info Card
                    Card(
                      elevation: 0,
                      color: AppColors.background.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              _report?.serviceAndCustomer.jobRef ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Action Buttons
                    ElevatedButton(
                      onPressed: () {
                        context.go('/dashboard');
                        context.push('/report-details/${widget.reportId}?draft=false');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('View Report'),
                    ),
                    const SizedBox(height: 12),
                    
                    OutlinedButton.icon(
                      onPressed: _downloadPdf,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ElevatedButton.icon(
                      onPressed: _sharePdf,
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    TextButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text(
                        'Back to Dashboard',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
