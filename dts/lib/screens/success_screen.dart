import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/reports_provider.dart';
import '../repositories/report_repository.dart';
import '../models/report_model.dart';
import '../models/agreement_model.dart';
import '../repositories/agreement_repository.dart';
import '../services/pdf_service.dart';

class SuccessScreen extends ConsumerStatefulWidget {
  final String reportId;
  final bool isAgreement;

  const SuccessScreen({
    super.key,
    required this.reportId,
    this.isAgreement = false,
  });

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen>
    with TickerProviderStateMixin {
  ReportModel? _report;
  AgreementModel? _agreement;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String _actionLoadingMessage = '';

  late AnimationController _checkController;
  late AnimationController _fadeController;
  late Animation<double> _checkScale;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    // Animated checkmark
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    // Fade-in for content
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    if (widget.isAgreement) {
      _loadAgreement();
    } else {
      _loadReport();
    }
  }

  void _startAnimations() {
    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });
  }

  Future<void> _loadReport() async {
    try {
      final repo = ref.read(reportRepositoryProvider);
      final report = await repo.getReportById(widget.reportId);
      setState(() {
        _report = report;
        _isLoading = false;
      });
      _startAnimations();
    } catch (e) {
      // Fallback: try to see if we can find it in standard reports
      try {
        final reports = ref.read(reportsProvider).reports;
        final found = reports.firstWhere(
          (r) => r.id == widget.reportId,
          orElse: () => throw Exception('Report not found'),
        );
        setState(() {
          _report = found;
          _isLoading = false;
        });
        _startAnimations();
      } catch (_) {
        setState(() => _isLoading = false);
        _startAnimations();
      }
    }
  }

  Future<void> _loadAgreement() async {
    try {
      final repo = ref.read(agreementRepositoryProvider);
      final agreement = await repo.getAgreementById(widget.reportId);
      setState(() {
        _agreement = agreement;
        _isLoading = false;
      });
      _startAnimations();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _startAnimations();
    }
  }

  void _downloadPdf() async {
    setState(() {
      _isActionLoading = true;
      _actionLoadingMessage = 'Preparing PDF for download...';
    });
    try {
      final pdfService = ref.read(pdfServiceProvider);
      if (widget.isAgreement) {
        if (_agreement != null) {
          await pdfService.printOrSaveAgreementPdf(_agreement!);
        }
      } else {
        if (_report != null) {
          await pdfService.printOrSavePdf(_report!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to generate PDF: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  void _sharePdf() async {
    setState(() {
      _isActionLoading = true;
      _actionLoadingMessage = 'Preparing PDF for sharing...';
    });
    try {
      final pdfService = ref.read(pdfServiceProvider);
      if (widget.isAgreement) {
        if (_agreement != null) {
          await pdfService.shareAgreementPdf(_agreement!);
        }
      } else {
        if (_report != null) {
          await pdfService.sharePdf(_report!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to share PDF: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Document-specific labeling
    String docTypeLabel;
    if (widget.isAgreement) {
      final type = _agreement?.documentType ?? 'Proposal';
      docTypeLabel = type == 'Agreement' ? 'Agreement' : 'Quotation';
    } else {
      docTypeLabel = 'Service Report';
    }

    final title = '$docTypeLabel Created Successfully!';

    final refNo = widget.isAgreement
        ? (_agreement?.offerNumber ?? 'Offer # Pending')
        : (_report?.serviceAndCustomer.jobRef ?? '');

    final customerName = widget.isAgreement
        ? (_agreement?.customerName ?? '')
        : (_report?.serviceAndCustomer.customerName ?? '');

    final docDate = widget.isAgreement
        ? (_agreement?.createdAt ?? DateTime.now())
        : (_report?.createdAt ?? DateTime.now());

    final formattedTime = DateFormat('dd MMMM yyyy, hh:mm a').format(docDate);

    final typeColor = widget.isAgreement
        ? (_agreement?.documentType == 'Agreement'
            ? AppColors.agreementGreen
            : AppColors.quotationBlue)
        : AppColors.reportOrange;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),

                        // Animated Success Checkmark
                        ScaleTransition(
                          scale: _checkScale,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.success,
                                  size: 56,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Fade-in content
                        FadeTransition(
                          opacity: _fadeIn,
                          child: Column(
                            children: [
                              // Title
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),

                              // Info Card
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: AppColors.border, width: 1),
                                ),
                                child: Column(
                                  children: [
                                    // Type badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        docTypeLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: typeColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Document number
                                    Text(
                                      refNo,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    if (customerName.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        customerName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 2),

                        // Action Buttons
                        FadeTransition(
                          opacity: _fadeIn,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // View Document
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.go('/dashboard');
                                  if (widget.isAgreement) {
                                    context.push(
                                        '/agreement-details/${widget.reportId}');
                                  } else {
                                    context.push(
                                        '/report-details/${widget.reportId}?draft=false');
                                  }
                                },
                                icon: const Icon(Icons.visibility_outlined,
                                    size: 20),
                                label: Text(
                                    'View $docTypeLabel'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Download + Share row
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _downloadPdf,
                                      icon: const Icon(
                                          Icons.download_rounded,
                                          size: 18),
                                      label: const Text('Download'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _sharePdf,
                                      icon: const Icon(Icons.share_rounded,
                                          size: 18),
                                      label: const Text('Share'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Back to Dashboard
                              TextButton.icon(
                                onPressed: () => context.go('/dashboard'),
                                icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary),
                                label: const Text(
                                  'Back to Dashboard',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Loading overlay
                  if (_isActionLoading)
                    Container(
                      color: Colors.black.withOpacity(0.4),
                      child: Center(
                        child: Card(
                          margin:
                              const EdgeInsets.symmetric(horizontal: 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  _actionLoadingMessage,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
