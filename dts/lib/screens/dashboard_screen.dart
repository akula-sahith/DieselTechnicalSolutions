import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/reports_provider.dart';
import '../providers/agreements_provider.dart';
import '../providers/estimates_provider.dart';
import '../providers/tax_invoices_provider.dart';
import '../providers/customers_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/document_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure all providers load data on dashboard initial mount
    Future.microtask(() {
      ref.read(estimatesProvider.notifier).loadEstimates();
      ref.read(taxInvoicesProvider.notifier).loadTaxInvoices();
      ref.read(customersProvider.notifier).loadCustomers();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 16) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final reportsState = ref.watch(reportsProvider);
    final reportsNotifier = ref.read(reportsProvider.notifier);
    final agreementsState = ref.watch(agreementsProvider);
    final agreementsNotifier = ref.read(agreementsProvider.notifier);
    final estimatesState = ref.watch(estimatesProvider);
    final estimatesNotifier = ref.read(estimatesProvider.notifier);
    final invoicesState = ref.watch(taxInvoicesProvider);
    final invoicesNotifier = ref.read(taxInvoicesProvider.notifier);
    final customersState = ref.watch(customersProvider);
    final customersNotifier = ref.read(customersProvider.notifier);

    final todayStr = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());
    final now = DateTime.now();

    // Today's Metrics Calculation
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

    final todayEstimates = estimatesState.estimates.where((e) {
      final date = e.createdAt ?? e.estimateDate;
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length;

    final todayInvoices = invoicesState.taxInvoices.where((i) {
      final date = i.createdAt ?? i.invoiceDate;
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length;

    final todayCustomers = customersState.customers.where((c) {
      return false; // Safely default or 0 if not tracked
    }).length;

    // Total Metrics Calculation
    final totalReports = reportsNotifier.totalReportsCount;
    final totalAgreements = agreementsState.totalCount + agreementsState.drafts.length;
    final totalEstimates = estimatesState.estimates.length;
    final totalInvoices = invoicesState.taxInvoices.length;
    final totalCustomers = customersState.customers.length;

    // Financial Metrics Calculation
    // Bills Pending: total value of active estimates not converted into tax invoices
    final pendingEstimates = estimatesState.estimates.where((e) => e.status != 'converted');
    final double billsPendingAmount = pendingEstimates.fold(0.0, (sum, e) => sum + (e.totalAmount ?? 0.0));

    // Revenue Generated: total value of all tax invoices
    final double revenueGeneratedAmount = invoicesState.taxInvoices.fold(0.0, (sum, i) => sum + (i.totalAmount ?? 0.0));

    // Unified recent activity feed
    final recentActivity = _buildRecentActivity(
      reportsState,
      agreementsState,
      estimatesState,
      invoicesState,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            reportsNotifier.refresh(),
            agreementsNotifier.refresh(),
            estimatesNotifier.refresh(),
            invoicesNotifier.refresh(),
            customersNotifier.refresh(),
          ]);
        },
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ──── 1. GREETING HEADER (Compact ERP Style) ────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting()}, ${authState.userName ?? 'User'}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              todayStr,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF334155),
                            size: 22,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No new notifications.')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ──── 2. TODAY'S BUSINESS SUMMARY ────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Overview",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryMiniCard(
                              label: "Reports",
                              value: todayReports.toString(),
                              icon: Icons.assignment_outlined,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryMiniCard(
                              label: "Agreements",
                              value: todayAgreements.toString(),
                              icon: Icons.handshake_outlined,
                              color: const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryMiniCard(
                              label: "Estimates",
                              value: todayEstimates.toString(),
                              icon: Icons.request_quote_outlined,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryMiniCard(
                              label: "Invoices",
                              value: todayInvoices.toString(),
                              icon: Icons.receipt_long_outlined,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryMiniCard(
                              label: "Customers",
                              value: todayCustomers.toString(),
                              icon: Icons.people_outline_rounded,
                              color: const Color(0xFF0891B2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ──── 3. TOTAL BUSINESS OVERVIEW ────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Overview",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryMiniCard(
                              label: "Reports",
                              value: totalReports.toString(),
                              icon: Icons.assignment_outlined,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryMiniCard(
                              label: "Agreements",
                              value: totalAgreements.toString(),
                              icon: Icons.handshake_outlined,
                              color: const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryMiniCard(
                              label: "Estimates",
                              value: totalEstimates.toString(),
                              icon: Icons.request_quote_outlined,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryMiniCard(
                              label: "Invoices",
                              value: totalInvoices.toString(),
                              icon: Icons.receipt_long_outlined,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryMiniCard(
                              label: "Customers",
                              value: totalCustomers.toString(),
                              icon: Icons.people_outline_rounded,
                              color: const Color(0xFF0891B2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ──── 3. FINANCIAL OVERVIEW ────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Financial Overview",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Bills Pending Card
                          Expanded(
                            child: _buildFinancialCard(
                              title: "Bills Pending",
                              subtitle: "${pendingEstimates.length} Unconverted Estimates",
                              amount: "₹${_formatCurrency(billsPendingAmount)}",
                              icon: Icons.hourglass_top_rounded,
                              accentColor: const Color(0xFFEA580C),
                              bgColor: const Color(0xFFFFF7ED),
                              borderColor: const Color(0xFFFFEDD5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Revenue Generated Card
                          Expanded(
                            child: _buildFinancialCard(
                              title: "Revenue Generated",
                              subtitle: "${invoicesState.taxInvoices.length} Total Invoices",
                              amount: "₹${_formatCurrency(revenueGeneratedAmount)}",
                              icon: Icons.account_balance_wallet_outlined,
                              accentColor: const Color(0xFF16A34A),
                              bgColor: const Color(0xFFF0FDF4),
                              borderColor: const Color(0xFFDCFCE7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ──── 4. QUICK ACTIONS ────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 10,
                        children: [
                          _buildQuickActionButton(
                            label: "Create Service Report",
                            icon: Icons.add_chart_rounded,
                            color: const Color(0xFF2563EB),
                            onTap: () => context.push('/create-report'),
                          ),
                          _buildQuickActionButton(
                            label: "Create Agreement",
                            icon: Icons.handshake_outlined,
                            color: const Color(0xFF059669),
                            onTap: () => context.push('/create-agreement'),
                          ),
                          _buildQuickActionButton(
                            label: "Create Estimate",
                            icon: Icons.post_add_rounded,
                            color: const Color(0xFFD97706),
                            onTap: () => context.push('/create-estimate'),
                          ),
                          _buildQuickActionButton(
                            label: "Create Tax Invoice",
                            icon: Icons.receipt_rounded,
                            color: const Color(0xFF7C3AED),
                            onTap: () => context.push('/create-tax-invoice'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ──── 5. RECENT ACTIVITY ────
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Recent Activity',
                  actionText: 'View All',
                  onActionTap: () => context.push('/reports'),
                ),
              ),

              if (recentActivity.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.inbox_rounded, size: 44, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 10),
                          Text(
                            'No recent activity',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create a document to see updates here',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
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

              // Bottom spacing for custom navigation bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  /// Helper widget for Today's Summary Card
  Widget _buildSummaryMiniCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Helper widget for Financial Overview Card
  Widget _buildFinancialCard({
    required String title,
    required String subtitle,
    required String amount,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Helper widget for Quick Action Grid Item
  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats currency with commas
  String _formatCurrency(double amount) {
    return NumberFormat('#,##,##0.00', 'en_IN').format(amount);
  }

  /// Unified Recent Activity feed Builder
  List<Widget> _buildRecentActivity(
    ReportsState reportsState,
    AgreementsState agreementsState,
    EstimatesState estimatesState,
    TaxInvoicesState invoicesState,
  ) {
    final List<_ActivityItem> items = [];

    // Reports & Drafts
    for (final report in reportsState.reports) {
      if (report.id != null) {
        items.add(_ActivityItem(
          date: report.createdAt ?? report.serviceAndCustomer.dateTime,
          widget: DocumentCard(
            documentNumber: report.serviceAndCustomer.jobRef,
            customerName: report.serviceAndCustomer.customerName,
            formattedDate: DateFormat('dd MMM yyyy, hh:mm a').format(report.createdAt ?? report.serviceAndCustomer.dateTime),
            documentType: DocumentType.report,
            statusText: 'Completed',
            isPending: false,
            onTap: () => context.push('/report-details/${report.id}?draft=false'),
          ),
        ));
      }
    }

    // Agreements & Drafts
    for (final agreement in agreementsState.agreements) {
      if (agreement.id != null) {
        items.add(_ActivityItem(
          date: agreement.date,
          widget: DocumentCard(
            documentNumber: agreement.offerNumber ?? 'Offer # Pending',
            customerName: agreement.customerName,
            formattedDate: DateFormat('dd MMM yyyy').format(agreement.date),
            documentType: agreement.documentType == 'Agreement' ? DocumentType.agreement : DocumentType.quotation,
            amount: '₹${_formatCurrency(agreement.grandTotal)}',
            onTap: () => context.push('/agreement-details/${agreement.id}'),
          ),
        ));
      }
    }

    // Estimates
    for (final estimate in estimatesState.estimates) {
      if (estimate.id != null) {
        items.add(_ActivityItem(
          date: estimate.estimateDate,
          widget: DocumentCard(
            documentNumber: estimate.estimateNumber ?? 'Estimate # Pending',
            customerName: estimate.estimateFor.customerName,
            formattedDate: DateFormat('dd MMM yyyy').format(estimate.estimateDate),
            documentType: DocumentType.quotation,
            amount: '₹${_formatCurrency(estimate.totalAmount ?? 0.0)}',
            statusText: estimate.status.toUpperCase(),
            isPending: estimate.status != 'converted',
            onTap: () => context.push('/estimate-details/${estimate.id}'),
          ),
        ));
      }
    }

    // Tax Invoices
    for (final invoice in invoicesState.taxInvoices) {
      if (invoice.id != null) {
        items.add(_ActivityItem(
          date: invoice.invoiceDate,
          widget: DocumentCard(
            documentNumber: invoice.invoiceNumber ?? 'Invoice # Pending',
            customerName: invoice.billTo.customerName,
            formattedDate: DateFormat('dd MMM yyyy').format(invoice.invoiceDate),
            documentType: DocumentType.agreement,
            amount: '₹${_formatCurrency(invoice.totalAmount ?? 0.0)}',
            statusText: 'Tax Invoice',
            isPending: false,
            onTap: () => context.push('/tax-invoice-details/${invoice.id}'),
          ),
        ));
      }
    }

    // Sort descending by date
    items.sort((a, b) => b.date.compareTo(a.date));

    return items.take(10).map((item) => item.widget).toList();
  }
}

class _ActivityItem {
  final DateTime date;
  final Widget widget;

  _ActivityItem({
    required this.date,
    required this.widget,
  });
}

