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

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final reportsState = ref.watch(reportsProvider);
    final reportsNotifier = ref.read(reportsProvider.notifier);
    final agreementsState = ref.watch(agreementsProvider);
    final agreementsNotifier = ref.read(agreementsProvider.notifier);

    final today = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());

    // Build unified recent activity feed
    final recentActivity = _buildRecentActivity(reportsState, agreementsState);

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
                                    today,
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

                        // ──── Statistics Row ────
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: "Today's Reports",
                                value: reportsNotifier.todayReportsCount.toString(),
                                icon: Icons.description_outlined,
                                color: AppColors.quotationBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatCard(
                                title: "Agreements",
                                value: agreementsState.totalCount.toString(),
                                icon: Icons.handshake_outlined,
                                color: AppColors.agreementGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatCard(
                                title: "Pending",
                                value: reportsNotifier.pendingReportsCount.toString(),
                                icon: Icons.schedule_outlined,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatCard(
                                title: "Total Docs",
                                value: (reportsNotifier.totalReportsCount + agreementsState.totalCount).toString(),
                                icon: Icons.folder_open_outlined,
                                color: const Color(0xFF6B7280),
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

            // ──── Quick Action Cards (Equal Prominence) ────
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

            // ──── Recent Activity Header ────
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Recent Activity',
                actionText: 'View All',
                onActionTap: () => context.push('/reports'),
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
                        const Text(
                          'No recent activity',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
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

  /// Builds a unified list of DocumentCard widgets from recent reports + agreements,
  /// sorted by date descending, capped at 8 items.
  List<Widget> _buildRecentActivity(
    ReportsState reportsState,
    AgreementsState agreementsState,
  ) {
    final List<_ActivityItem> items = [];

    // Add drafts (pending reports)
    for (final draft in reportsState.drafts.take(5)) {
      items.add(_ActivityItem(
        date: draft.serviceAndCustomer.dateTime,
        widget: Builder(
          builder: (context) => DocumentCard(
            documentNumber: draft.serviceAndCustomer.jobRef,
            customerName: draft.serviceAndCustomer.customerName,
            formattedDate: DateFormat('dd MMM yyyy, hh:mm a')
                .format(draft.serviceAndCustomer.dateTime),
            documentType: DocumentType.report,
            statusText: 'Pending',
            isPending: true,
            onTap: () {
              context.push(
                  '/report-details/${draft.serviceAndCustomer.jobRef}?draft=true');
            },
          ),
        ),
      ));
    }

    // Add submitted reports
    for (final report in reportsState.reports.take(5)) {
      items.add(_ActivityItem(
        date: report.createdAt ?? report.serviceAndCustomer.dateTime,
        widget: Builder(
          builder: (context) => DocumentCard(
            documentNumber: report.serviceAndCustomer.jobRef,
            customerName: report.serviceAndCustomer.customerName,
            formattedDate: DateFormat('dd MMM yyyy, hh:mm a')
                .format(report.createdAt ?? report.serviceAndCustomer.dateTime),
            documentType: DocumentType.report,
            statusText: 'Completed',
            isPending: false,
            onTap: () {
              context.push('/report-details/${report.id}?draft=false');
            },
          ),
        ),
      ));
    }

    // Add agreements
    for (final agreement in agreementsState.agreements.take(5)) {
      items.add(_ActivityItem(
        date: agreement.date,
        widget: Builder(
          builder: (context) => DocumentCard(
            documentNumber: agreement.offerNumber ?? 'Offer # Pending',
            customerName: agreement.customerName,
            formattedDate: DateFormat('dd MMM yyyy').format(agreement.date),
            documentType: agreement.documentType == 'Agreement'
                ? DocumentType.agreement
                : DocumentType.quotation,
            amount: '₹${agreement.grandTotal.toStringAsFixed(0)}',
            onTap: () {
              context.push('/agreement-details/${agreement.id}');
            },
          ),
        ),
      ));
    }

    // Sort by date descending and take 8
    items.sort((a, b) => b.date.compareTo(a.date));
    return items.take(8).map((item) => item.widget).toList();
  }
}

/// Helper class to sort activity items by date
class _ActivityItem {
  final DateTime date;
  final Widget widget;

  _ActivityItem({required this.date, required this.widget});
}
