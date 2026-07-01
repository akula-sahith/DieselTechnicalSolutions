import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/reports_provider.dart';
import '../providers/agreements_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/quick_action_card.dart';
import '../widgets/common/document_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedFilter = 'all'; // 'all', 'today', 'reports', 'proposals', 'pending'

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilter == filter) {
        _selectedFilter = 'all';
      } else {
        _selectedFilter = filter;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final reportsState = ref.watch(reportsProvider);
    final reportsNotifier = ref.read(reportsProvider.notifier);
    final agreementsState = ref.watch(agreementsProvider);
    final agreementsNotifier = ref.read(agreementsProvider.notifier);

    final todayStr = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());

    // Compute counts
    final now = DateTime.now();
    final todayReports = reportsState.reports.where((r) {
      final date = r.createdAt ?? r.serviceAndCustomer.dateTime;
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length + reportsState.drafts.where((d) {
      final date = d.createdAt ?? d.serviceAndCustomer.dateTime;
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length;

    final todayAgreements = agreementsState.agreements.where((a) {
      final date = a.createdAt ?? a.date;
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length + agreementsState.drafts.where((d) {
      final date = d.createdAt ?? d.date;
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length;

    final todayDocsCount = todayReports + todayAgreements;
    final totalReports = reportsNotifier.totalReportsCount;
    final totalAgreements = agreementsState.totalCount + agreementsState.drafts.length;
    final totalPending = reportsState.drafts.length + agreementsState.drafts.length;

    // Build filtered unified recent activity feed
    final recentActivity = _buildRecentActivity(reportsState, agreementsState, _selectedFilter);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await reportsNotifier.refresh();
          await agreementsNotifier.refresh();
        },
        child: CustomScrollView(
          slivers: [
            // ──── Header with Gradient ────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B2545), Color(0xFF134074)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_greeting()}, ${authState.userName ?? 'Technician'} 👋',
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      todayStr,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                            ),
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined,
                                      color: Colors.white, size: 26),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No new notifications.')),
                                    );
                                  },
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // ──── Statistics Row (Interactive Filters) ────
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: "Today Docs",
                                value: todayDocsCount.toString(),
                                icon: Icons.today_outlined,
                                color: AppColors.quotationBlue,
                                isSelected: _selectedFilter == 'today',
                                onTap: () => _toggleFilter('today'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatCard(
                                title: "Reports",
                                value: totalReports.toString(),
                                icon: Icons.description_outlined,
                                color: const Color(0xFFEE6C4D),
                                isSelected: _selectedFilter == 'reports',
                                onTap: () => _toggleFilter('reports'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatCard(
                                title: "AMC Proposals",
                                value: totalAgreements.toString(),
                                icon: Icons.handshake_outlined,
                                color: AppColors.agreementGreen,
                                isSelected: _selectedFilter == 'proposals',
                                onTap: () => _toggleFilter('proposals'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatCard(
                                title: "Pending / Drafts",
                                value: totalPending.toString(),
                                icon: Icons.schedule_outlined,
                                color: AppColors.warning,
                                isSelected: _selectedFilter == 'pending',
                                onTap: () => _toggleFilter('pending'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ──── Quick Actions Header ────
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Quick Actions'),
            ),

            // ──── Quick Action Cards ────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    QuickActionCard(
                      title: 'Service\nReport',
                      subtitle: 'Create new \n report',
                      icon: Icons.description_outlined,
                      gradientColors: const [Color(0xFFEE6C4D), Color(0xFFE85D3A)],
                      onTap: () => context.push('/create-report'),
                    ),
                    const SizedBox(width: 12),
                    QuickActionCard(
                      title: 'AMC\nProposal',
                      subtitle: 'Draft Agreement or Quotation',
                      icon: Icons.handshake_outlined,
                      gradientColors: const [Color(0xFF059669), Color(0xFF047857)],
                      onTap: () => context.push('/create-agreement'),
                    ),
                  ],
                ),
              ),
            ),

            // ──── Dynamic Activity Header ────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: _selectedFilter == 'all'
                    ? 'Recent Activity'
                    : _selectedFilter == 'today'
                        ? 'Today\'s Documents'
                        : _selectedFilter == 'reports'
                            ? 'Service Reports'
                            : _selectedFilter == 'proposals'
                                ? 'AMC Proposals'
                                : 'Pending Drafts',
                actionText: 'View All',
                onActionTap: () {
                  if (_selectedFilter == 'reports') {
                    context.push('/reports');
                  } else if (_selectedFilter == 'proposals') {
                    context.push('/agreements');
                  } else if (_selectedFilter == 'pending') {
                    context.push('/drafts');
                  } else {
                    context.push('/reports');
                  }
                },
              ),
            ),

            // ──── Recent Activity Feed ────
            if (recentActivity.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 48, color: AppColors.textLight.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          _selectedFilter == 'all'
                              ? 'No recent activity'
                              : 'No matching documents found',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_selectedFilter == 'all')
                          const Text(
                            'Create your first document to get started',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => recentActivity[index],
                  childCount: recentActivity.length,
                ),
              ),

            // Bottom padding for nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  /// Builds a filtered list of DocumentCard widgets
  List<Widget> _buildRecentActivity(
    ReportsState reportsState,
    AgreementsState agreementsState,
    String filter,
  ) {
    final List<_ActivityItem> items = [];

    // Add report drafts
    for (final draft in reportsState.drafts) {
      if (draft.id != null) {
        items.add(_ActivityItem(
          id: draft.id!,
          isReport: true,
          isDraft: true,
          date: draft.serviceAndCustomer.dateTime,
          widget: Builder(
            builder: (context) => DocumentCard(
              documentNumber: draft.serviceAndCustomer.jobRef,
              customerName: draft.serviceAndCustomer.customerName,
              formattedDate: DateFormat('dd MMM yyyy, hh:mm a').format(draft.serviceAndCustomer.dateTime),
              documentType: DocumentType.report,
              statusText: 'Pending',
              isPending: true,
              onTap: () => context.push('/report-details/${draft.id}?draft=true'),
            ),
          ),
        ));
      }
    }

    // Add reports
    for (final report in reportsState.reports) {
      if (report.id != null) {
        items.add(_ActivityItem(
          id: report.id!,
          isReport: true,
          isDraft: false,
          date: report.createdAt ?? report.serviceAndCustomer.dateTime,
          widget: Builder(
            builder: (context) => DocumentCard(
              documentNumber: report.serviceAndCustomer.jobRef,
              customerName: report.serviceAndCustomer.customerName,
              formattedDate: DateFormat('dd MMM yyyy, hh:mm a').format(report.createdAt ?? report.serviceAndCustomer.dateTime),
              documentType: DocumentType.report,
              statusText: 'Completed',
              isPending: false,
              onTap: () => context.push('/report-details/${report.id}?draft=false'),
            ),
          ),
        ));
      }
    }

    // Add agreement drafts
    for (final draft in agreementsState.drafts) {
      if (draft.id != null) {
        items.add(_ActivityItem(
          id: draft.id!,
          isReport: false,
          isDraft: true,
          date: draft.date,
          widget: Builder(
            builder: (context) => DocumentCard(
              documentNumber: draft.offerNumber ?? 'Offer # Pending',
              customerName: draft.customerName,
              formattedDate: DateFormat('dd MMM yyyy').format(draft.date),
              documentType: draft.documentType == 'Agreement' ? DocumentType.agreement : DocumentType.quotation,
              amount: '₹${draft.grandTotal.toStringAsFixed(0)}',
              statusText: 'Pending',
              isPending: true,
              onTap: () => context.push('/agreement-details/${draft.id}?draft=true'),
            ),
          ),
        ));
      }
    }

    // Add agreements
    for (final agreement in agreementsState.agreements) {
      if (agreement.id != null) {
        items.add(_ActivityItem(
          id: agreement.id!,
          isReport: false,
          isDraft: false,
          date: agreement.date,
          widget: Builder(
            builder: (context) => DocumentCard(
              documentNumber: agreement.offerNumber ?? 'Offer # Pending',
              customerName: agreement.customerName,
              formattedDate: DateFormat('dd MMM yyyy').format(agreement.date),
              documentType: agreement.documentType == 'Agreement' ? DocumentType.agreement : DocumentType.quotation,
              amount: '₹${agreement.grandTotal.toStringAsFixed(0)}',
              onTap: () => context.push('/agreement-details/${agreement.id}'),
            ),
          ),
        ));
      }
    }

    // Sort by date descending
    items.sort((a, b) => b.date.compareTo(a.date));

    // Filter items
    Iterable<_ActivityItem> filtered = items;
    if (filter == 'today') {
      final now = DateTime.now();
      filtered = items.where((item) =>
          item.date.year == now.year &&
          item.date.month == now.month &&
          item.date.day == now.day);
    } else if (filter == 'reports') {
      filtered = items.where((item) => item.isReport);
    } else if (filter == 'proposals') {
      filtered = items.where((item) => !item.isReport);
    } else if (filter == 'pending') {
      filtered = items.where((item) => item.isDraft);
    }

    return filtered.take(15).map((item) => item.widget).toList();
  }
}

/// Helper class to sort activity items by date
class _ActivityItem {
  final String id;
  final bool isReport;
  final bool isDraft;
  final DateTime date;
  final Widget widget;

  _ActivityItem({
    required this.id,
    required this.isReport,
    required this.isDraft,
    required this.date,
    required this.widget,
  });
}
