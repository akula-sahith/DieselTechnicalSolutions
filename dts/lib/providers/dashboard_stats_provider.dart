import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';

class MonthlyAnalyticItem {
  final int year;
  final int month;
  final String monthName;
  final double revenue;
  final double costs;
  final double profit;
  final int taxInvoicesCount;
  final int cashInvoicesCount;
  final int estimatesCount;
  final int purchaseBillsCount;
  final int agreementsCount;
  final int reportsCount;
  final int deliveryChallansCount;
  final int totalTransactions;

  MonthlyAnalyticItem({
    required this.year,
    required this.month,
    required this.monthName,
    required this.revenue,
    required this.costs,
    required this.profit,
    required this.taxInvoicesCount,
    required this.cashInvoicesCount,
    required this.estimatesCount,
    required this.purchaseBillsCount,
    required this.agreementsCount,
    required this.reportsCount,
    required this.deliveryChallansCount,
    required this.totalTransactions,
  });

  factory MonthlyAnalyticItem.fromJson(Map<String, dynamic> json) {
    return MonthlyAnalyticItem(
      year: (json['year'] as num?)?.toInt() ?? 2026,
      month: (json['month'] as num?)?.toInt() ?? 9,
      monthName: json['monthName'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      costs: (json['costs'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      taxInvoicesCount: (json['taxInvoicesCount'] as num?)?.toInt() ?? 0,
      cashInvoicesCount: (json['cashInvoicesCount'] as num?)?.toInt() ?? 0,
      estimatesCount: (json['estimatesCount'] as num?)?.toInt() ?? 0,
      purchaseBillsCount: (json['purchaseBillsCount'] as num?)?.toInt() ?? 0,
      agreementsCount: (json['agreementsCount'] as num?)?.toInt() ?? 0,
      reportsCount: (json['reportsCount'] as num?)?.toInt() ?? 0,
      deliveryChallansCount: (json['deliveryChallansCount'] as num?)?.toInt() ?? 0,
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? 0,
    );
  }
}

class WeeklyAnalyticItem {
  final String weekLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final String dateRangeLabel;
  final double revenue;
  final double profit;
  final int invoicesCount;
  final int reportsCount;

  WeeklyAnalyticItem({
    required this.weekLabel,
    this.startDate,
    this.endDate,
    this.dateRangeLabel = '',
    required this.revenue,
    required this.profit,
    required this.invoicesCount,
    required this.reportsCount,
  });

  factory WeeklyAnalyticItem.fromJson(Map<String, dynamic> json) {
    return WeeklyAnalyticItem(
      weekLabel: json['weekLabel'] ?? '',
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      dateRangeLabel: json['dateRangeLabel'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      invoicesCount: (json['invoicesCount'] as num?)?.toInt() ?? 0,
      reportsCount: (json['reportsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardStats {
  final double estimateAmountPending;
  final double revenueGenerated;
  final double paymentReceived;
  final double outstandingAmount;
  final double totalProfit;
  final double purchaseBills;
  final List<MonthlyAnalyticItem> monthlyAnalytics;
  final List<WeeklyAnalyticItem> weeklyAnalytics;

  DashboardStats({
    required this.estimateAmountPending,
    required this.revenueGenerated,
    required this.paymentReceived,
    required this.outstandingAmount,
    this.totalProfit = 0.0,
    required this.purchaseBills,
    this.monthlyAnalytics = const [],
    this.weeklyAnalytics = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final listRaw = json['weeklyAnalytics'] as List?;
    final weeklyList = listRaw != null
        ? listRaw.map((e) => WeeklyAnalyticItem.fromJson(e as Map<String, dynamic>)).toList()
        : <WeeklyAnalyticItem>[];

    final monthRaw = json['monthlyAnalytics'] as List?;
    final monthlyList = monthRaw != null
        ? monthRaw.map((e) => MonthlyAnalyticItem.fromJson(e as Map<String, dynamic>)).toList()
        : <MonthlyAnalyticItem>[];

    return DashboardStats(
      estimateAmountPending: (json['estimateAmountPending'] as num?)?.toDouble() ?? 0.0,
      revenueGenerated: (json['revenueGenerated'] as num?)?.toDouble() ?? 0.0,
      paymentReceived: (json['paymentReceived'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['totalProfit'] as num?)?.toDouble() ?? 0.0,
      purchaseBills: (json['purchaseBills'] as num?)?.toDouble() ?? 0.0,
      monthlyAnalytics: monthlyList,
      weeklyAnalytics: weeklyList,
    );
  }
}

class DashboardStatsNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final ApiService _apiService;

  DashboardStatsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    fetchStats();
  }

  Future<void> fetchStats() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.get('/dashboard/stats');
      final data = response.data['data'] as Map<String, dynamic>;
      state = AsyncValue.data(DashboardStats.fromJson(data));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final dashboardStatsProvider = StateNotifierProvider<DashboardStatsNotifier, AsyncValue<DashboardStats>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DashboardStatsNotifier(apiService);
});
