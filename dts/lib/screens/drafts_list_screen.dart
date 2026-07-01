import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/reports_provider.dart';
import '../providers/agreements_provider.dart';
import '../widgets/common/document_card.dart';
import '../widgets/common/empty_state_widget.dart';

class DraftsListScreen extends ConsumerStatefulWidget {
  const DraftsListScreen({super.key});

  @override
  ConsumerState<DraftsListScreen> createState() => _DraftsListScreenState();
}

class _DraftsListScreenState extends ConsumerState<DraftsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsProvider);
    final agreementsState = ref.watch(agreementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Drafts'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Service Reports (${reportsState.drafts.length})',
            ),
            Tab(
              text: 'AMC Proposals (${agreementsState.drafts.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsDraftsList(reportsState.drafts),
          _buildAgreementsDraftsList(agreementsState.drafts),
        ],
      ),
    );
  }

  Widget _buildReportsDraftsList(List<dynamic> drafts) {
    if (drafts.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.description_outlined,
          title: 'No Pending Reports',
          subtitle: 'All service reports are submitted.',
          actionLabel: 'Create Report',
          onAction: () => context.push('/create-report'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: drafts.length,
      itemBuilder: (context, index) {
        final report = drafts[index];
        final formattedDate = DateFormat('dd MMM yyyy, hh:mm a')
            .format(report.serviceAndCustomer.dateTime);

        return DocumentCard(
          documentNumber: report.serviceAndCustomer.jobRef,
          customerName: report.serviceAndCustomer.customerName,
          formattedDate: formattedDate,
          documentType: DocumentType.report,
          statusText: 'Pending',
          isPending: true,
          onTap: () {
            context.push('/report-details/${report.id}?draft=true');
          },
        );
      },
    );
  }

  Widget _buildAgreementsDraftsList(List<dynamic> drafts) {
    if (drafts.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.handshake_outlined,
          title: 'No Pending Proposals',
          subtitle: 'All agreements and quotations are submitted.',
          actionLabel: 'Create Proposal',
          onAction: () => context.push('/create-agreement'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: drafts.length,
      itemBuilder: (context, index) {
        final agreement = drafts[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(agreement.date);

        return DocumentCard(
          documentNumber: agreement.offerNumber ?? 'Offer # Pending',
          customerName: agreement.customerName,
          formattedDate: formattedDate,
          documentType: agreement.documentType == 'Agreement'
              ? DocumentType.agreement
              : DocumentType.quotation,
          statusText: 'Pending',
          isPending: true,
          amount: '₹${agreement.grandTotal.toStringAsFixed(2)}',
          onTap: () {
            context.push('/agreement-details/${agreement.id}?draft=true');
          },
        );
      },
    );
  }
}
