import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/financial_analytics_model.dart';
import '../repositories/analytics_repository.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/common/adaptive_layout.dart';

class FinancialAnalysisScreen extends ConsumerStatefulWidget {
  final int year;
  final int month;

  const FinancialAnalysisScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  ConsumerState<FinancialAnalysisScreen> createState() => _FinancialAnalysisScreenState();
}

class _FinancialAnalysisScreenState extends ConsumerState<FinancialAnalysisScreen> {
  bool _isLoading = true;
  String? _error;
  MonthlyDetailModel? _detail;
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.year;
    _selectedMonth = widget.month;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(analyticsRepositoryProvider);
      final res = await repo.getMonthlyDetail(_selectedYear, _selectedMonth);
      setState(() {
        _detail = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##,##0.00', 'en_IN').format(amount);
  }

  Widget _buildMonthSelectorHeader() {
    final date = DateTime(_selectedYear, _selectedMonth, 1);
    final monthStr = DateFormat('MMMM yyyy').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF0F172A)),
            onPressed: () {
              setState(() {
                if (_selectedMonth == 1) {
                  _selectedMonth = 12;
                  _selectedYear--;
                } else {
                  _selectedMonth--;
                }
              });
              _fetchDetail();
            },
            tooltip: 'Previous Month',
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                monthStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFF0F172A)),
            onPressed: () {
              setState(() {
                if (_selectedMonth == 12) {
                  _selectedMonth = 1;
                  _selectedYear++;
                } else {
                  _selectedMonth++;
                }
              });
              _fetchDetail();
            },
            tooltip: 'Next Month',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdaptiveLayout.isDesktop(context);

    return AdaptiveLayout(
      currentRoute: '/financial-analysis',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_detail?.monthName.isNotEmpty == true ? 'Financial Analysis - ${_detail!.monthName}' : 'Financial Analysis'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchDetail,
              tooltip: 'Refresh Analytics',
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: -1),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDetail,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _detail == null
                    ? const Center(child: Text('No analytical data available.'))
                    : RefreshIndicator(
                        onRefresh: _fetchDetail,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Month Selector Header
                              _buildMonthSelectorHeader(),

                              // 1. Month Summary Section Header
                              Text(
                                '${_detail!.monthName} Overview',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Summary Cards Grid
                              _buildMonthSummaryGrid(isDesktop),
                              const SizedBox(height: 24),

                              // 2. Revenue & Cost Breakdown Section
                              const Text(
                                'Financial Breakdown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 12),

                              isDesktop
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildRevenueBreakdownCard()),
                                        const SizedBox(width: 16),
                                        Expanded(child: _buildCostBreakdownCard()),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildRevenueBreakdownCard(),
                                        const SizedBox(height: 16),
                                        _buildCostBreakdownCard(),
                                      ],
                                    ),
                              const SizedBox(height: 24),

                              // 3. Document Analysis Section
                              const Text(
                                'Document Analysis',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDocumentAnalysisCard(isDesktop),
                              const SizedBox(height: 24),

                              // 4. Week-wise Analysis Section
                              const Text(
                                'Week-Wise Breakdown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildWeeklyAnalysisList(isDesktop),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildMonthSummaryGrid(bool isDesktop) {
    final d = _detail!;
    final cards = [
      _buildSummaryCard(
        title: 'Total Revenue',
        amount: '₹${_formatCurrency(d.totalRevenue)}',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF16A34A),
        bgColor: const Color(0xFFF0FDF4),
      ),
      _buildSummaryCard(
        title: 'Total Costs',
        amount: '₹${_formatCurrency(d.totalCosts)}',
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
      ),
      _buildSummaryCard(
        title: 'Net Profit',
        amount: '₹${_formatCurrency(d.netProfit)}',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
      ),
      _buildSummaryCard(
        title: 'Total Transactions',
        amount: '${d.totalTransactions}',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: c,
                  ),
                ))
            .toList(),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: cards,
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownCard() {
    final d = _detail!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.arrow_upward_rounded, color: Color(0xFF16A34A), size: 18),
              SizedBox(width: 6),
              Text(
                'Revenue Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildBreakdownRow('Tax Invoices', d.taxInvoices.count, d.taxInvoices.totalAmount, const Color(0xFF7C3AED)),
          const SizedBox(height: 10),
          _buildBreakdownRow('Cash Invoices', d.cashInvoices.count, d.cashInvoices.totalAmount, AppColors.accent),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Revenue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('₹${_formatCurrency(d.totalRevenue)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF16A34A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdownCard() {
    final d = _detail!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.arrow_downward_rounded, color: Color(0xFFDC2626), size: 18),
              SizedBox(width: 6),
              Text(
                'Cost Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildBreakdownRow('Purchase Bills', d.purchaseBills.count, d.purchaseBills.totalAmount, const Color(0xFFDC2626)),
          const SizedBox(height: 10),
          _buildBreakdownRow('Other Costs / Expenses', 0, d.totalCosts > d.purchaseBills.totalAmount ? d.totalCosts - d.purchaseBills.totalAmount : 0.0, const Color(0xFFD97706)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Costs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('₹${_formatCurrency(d.totalCosts)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFDC2626))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int count, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$count item(s)',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('₹${_formatCurrency(amount)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }

  Widget _buildDocumentAnalysisCard(bool isDesktop) {
    final d = _detail!;
    final docs = [
      {'name': 'Tax Invoices', 'count': d.taxInvoices.count, 'amount': d.taxInvoices.totalAmount, 'icon': Icons.receipt_long_outlined, 'color': const Color(0xFF7C3AED)},
      {'name': 'Cash Invoices', 'count': d.cashInvoices.count, 'amount': d.cashInvoices.totalAmount, 'icon': Icons.subtitles_outlined, 'color': AppColors.accent},
      {'name': 'Estimates', 'count': d.estimates.count, 'amount': d.estimates.totalAmount, 'icon': Icons.request_quote_outlined, 'color': const Color(0xFFD97706)},
      {'name': 'Agreements', 'count': d.agreements.count, 'amount': d.agreements.totalAmount, 'icon': Icons.handshake_outlined, 'color': const Color(0xFF059669)},
      {'name': 'Purchase Bills', 'count': d.purchaseBills.count, 'amount': d.purchaseBills.totalAmount, 'icon': Icons.shopping_bag_outlined, 'color': const Color(0xFFDC2626)},
      {'name': 'Service Reports', 'count': d.serviceReports.count, 'amount': null, 'icon': Icons.description_outlined, 'color': AppColors.reportOrange},
      {'name': 'Delivery Challans', 'count': d.deliveryChallans.count, 'amount': null, 'icon': Icons.local_shipping_outlined, 'color': const Color(0xFF0891B2)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: docs.map((doc) {
          final color = doc['color'] as Color;
          final amount = doc['amount'] as double?;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(doc['icon'] as IconData, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    doc['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${doc['count']} docs',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: Text(
                    amount != null ? '₹${_formatCurrency(amount)}' : 'N/A',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: amount != null ? color : AppColors.textLight),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyAnalysisList(bool isDesktop) {
    final d = _detail!;
    if (d.weeklyAnalytics.isEmpty) {
      return const Text('No weekly analytics available for this month.');
    }

    return Column(
      children: d.weeklyAnalytics.map((week) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      week.weekLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        week.dateRangeLabel,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Revenue', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('₹${_formatCurrency(week.revenue)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF16A34A))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Costs', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('₹${_formatCurrency(week.costs)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFDC2626))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Profit', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('₹${_formatCurrency(week.profit)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF059669))),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(
                          '/week-documents?startDate=${Uri.encodeComponent(week.startDate)}&endDate=${Uri.encodeComponent(week.endDate)}&label=${Uri.encodeComponent(week.dateRangeLabel)}',
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: Text('${week.documentsCount} Docs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
