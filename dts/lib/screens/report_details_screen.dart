import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/report_model.dart';
import '../providers/reports_provider.dart';
import '../repositories/report_repository.dart';
import '../services/pdf_service.dart';

class ReportDetailsScreen extends ConsumerStatefulWidget {
  final String reportId;
  final bool isLocalDraft;

  const ReportDetailsScreen({
    super.key,
    required this.reportId,
    required this.isLocalDraft,
  });

  @override
  ConsumerState<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends ConsumerState<ReportDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportModel? _report;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    if (widget.isLocalDraft) {
      final drafts = ref.read(reportsProvider).drafts;
      final draft = drafts.firstWhere(
        (element) => element.serviceAndCustomer.jobRef == widget.reportId,
        orElse: () => throw Exception('Draft not found'),
      );
      setState(() {
        _report = draft;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final repo = ref.read(reportRepositoryProvider);
        final report = await repo.getReportById(widget.reportId);
        setState(() {
          _report = report;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _downloadPdf() async {
    if (_report == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...'), duration: Duration(seconds: 1)),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing PDF for sharing...'), duration: Duration(seconds: 1)),
    );
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error: $_error', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadReport, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Details')),
        body: const Center(child: Text('Report not found.')),
      );
    }

    final report = _report!;
    final formattedDate = DateFormat('dd MMMM yyyy, hh:mm a').format(report.serviceAndCustomer.dateTime);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(report.serviceAndCustomer.jobRef),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _downloadPdf,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Checklist'),
            Tab(text: 'Parts'),
            Tab(text: 'Photos'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(report, formattedDate),
                _buildChecklistTab(report),
                _buildPartsTab(report),
                _buildAttachmentsTab(report),
              ],
            ),
          ),
          
          // Action Buttons Bottom Bar
          if (!widget.isLocalDraft)
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

  Widget _buildOverviewTab(ReportModel report, String formattedDate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        report.serviceAndCustomer.jobRef,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      _buildStatusBadge(widget.isLocalDraft),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(formattedDate, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Customer Details
          _buildInfoGroup(
            title: 'CUSTOMER DETAILS',
            icon: Icons.business,
            items: [
              _buildInfoRow('Customer Name', report.serviceAndCustomer.customerName),
              _buildInfoRow('Site Location', report.serviceAndCustomer.siteLocation),
              _buildInfoRow('Contact Person', report.serviceAndCustomer.contactPerson),
              _buildInfoRow('Contact Number', report.serviceAndCustomer.contactNumber),
            ],
          ),

          // Equipment Details
          _buildInfoGroup(
            title: 'EQUIPMENT DETAILS',
            icon: Icons.settings,
            items: [
              _buildInfoRow('Generator Make/Model', report.equipmentAndEngine.generatorMakeModel),
              _buildInfoRow('Capacity', report.equipmentAndEngine.capacity),
              _buildInfoRow('Engine Serial No', report.equipmentAndEngine.engineSerialNo),
              _buildInfoRow('Alternator Serial No', report.equipmentAndEngine.alternatorSerialNo),
              _buildInfoRow('Hour Meter', report.equipmentAndEngine.hourMeter),
              _buildInfoRow('Hours', report.equipmentAndEngine.hours?.toString() ?? 'N/A'),
              _buildInfoRow('Battery Volt', report.equipmentAndEngine.batteryStatusVolt),
            ],
          ),

          // Remarks
          _buildInfoGroup(
            title: 'REMARKS & ACTION PLAN',
            icon: Icons.comment,
            items: [
              _buildInfoRow('Observations', report.remarksAndActionPlan.observations),
              _buildInfoRow(
                'Next Due Date',
                report.remarksAndActionPlan.nextServiceDueDate != null
                    ? DateFormat('dd MMMM yyyy').format(report.remarksAndActionPlan.nextServiceDueDate!)
                    : 'N/A',
              ),
              _buildInfoRow('Next Due Hours', report.remarksAndActionPlan.nextServiceDueHours?.toString() ?? 'N/A'),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChecklistTab(ReportModel report) {
    if (report.serviceChecklist.isEmpty) {
      return const Center(child: Text('No checklist recorded.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: report.serviceChecklist.length,
      itemBuilder: (context, index) {
        final item = report.serviceChecklist[index];
        Color statusColor;
        switch (item.status) {
          case 'ok':
            statusColor = AppColors.success;
            break;
          case 'req':
            statusColor = AppColors.primary;
            break;
          default:
            statusColor = AppColors.textLight;
        }

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.parameter,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPartsTab(ReportModel report) {
    if (report.partsUsed.isEmpty) {
      return const Center(child: Text('No parts replaced or consumables used.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: report.partsUsed.length,
      itemBuilder: (context, index) {
        final part = report.partsUsed[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(part.partDescription, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Qty: ${part.qty}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentsTab(ReportModel report) {
    final signatureUrl = report.authorization.technicianSignatureUrl;
    final photoUrl = report.authorization.customerPhotoUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Technician Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technician: ${report.authorization.technicianName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (report.authorization.technicianDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(report.authorization.technicianDate!)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Signature
          const SizedBox(height: 16),
          const Text(
            'Technician Signature',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Container(
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: widget.isLocalDraft
                  ? (signatureUrl.isNotEmpty ? Image.file(File(signatureUrl), fit: BoxFit.contain) : const Center(child: Text('No Signature')))
                  : (signatureUrl.isNotEmpty ? Image.network(signatureUrl, fit: BoxFit.contain) : const Center(child: Text('No Signature'))),
            ),
          ),

          // Customer Representative Info
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Representative: ${report.authorization.customerRepresentativeName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (report.authorization.customerDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(report.authorization.customerDate!)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Customer Photo
          const SizedBox(height: 16),
          const Text(
            'Customer Representative / Photo Capture',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: widget.isLocalDraft
                  ? (photoUrl.isNotEmpty ? Image.file(File(photoUrl), fit: BoxFit.cover) : const Center(child: Text('No Photo')))
                  : (photoUrl.isNotEmpty ? Image.network(photoUrl, fit: BoxFit.cover) : const Center(child: Text('No Photo'))),
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoGroup({required String title, required IconData icon, required List<Widget> items}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(icon, color: AppColors.secondary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary, letterSpacing: 0.5),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDraft) {
    final text = isDraft ? 'Pending' : 'Completed';
    final bgColor = isDraft ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15);
    final textColor = isDraft ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
