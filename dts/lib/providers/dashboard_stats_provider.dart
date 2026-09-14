import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';

class WeeklyAnalyticItem {
  final String weekLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final double revenue;
  final double profit;
  final int invoicesCount;
  final int reportsCount;

  WeeklyAnalyticItem({
    required this.weekLabel,
    this.startDate,
    this.endDate,
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
  final List<WeeklyAnalyticItem> weeklyAnalytics;

  DashboardStats({
    required this.estimateAmountPending,
    required this.revenueGenerated,
    required this.paymentReceived,
    required this.outstandingAmount,
    this.totalProfit = 0.0,
    required this.purchaseBills,
    this.weeklyAnalytics = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final listRaw = json['weeklyAnalytics'] as List?;
    final weeklyList = listRaw != null
        ? listRaw.map((e) => WeeklyAnalyticItem.fromJson(e as Map<String, dynamic>)).toList()
        : <WeeklyAnalyticItem>[];

    return DashboardStats(
      estimateAmountPending: (json['estimateAmountPending'] as num?)?.toDouble() ?? 0.0,
      revenueGenerated: (json['revenueGenerated'] as num?)?.toDouble() ?? 0.0,
      paymentReceived: (json['paymentReceived'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['totalProfit'] as num?)?.toDouble() ?? 0.0,
      purchaseBills: (json['purchaseBills'] as num?)?.toDouble() ?? 0.0,
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
