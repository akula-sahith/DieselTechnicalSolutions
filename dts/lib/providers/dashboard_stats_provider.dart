import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/api_service.dart';

class DashboardStats {
  final double estimateAmountPending;
  final double revenueGenerated;
  final double paymentReceived;
  final double outstandingAmount;
  final double purchaseBills;

  DashboardStats({
    required this.estimateAmountPending,
    required this.revenueGenerated,
    required this.paymentReceived,
    required this.outstandingAmount,
    required this.purchaseBills,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      estimateAmountPending: (json['estimateAmountPending'] as num?)?.toDouble() ?? 0.0,
      revenueGenerated: (json['revenueGenerated'] as num?)?.toDouble() ?? 0.0,
      paymentReceived: (json['paymentReceived'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble() ?? 0.0,
      purchaseBills: (json['purchaseBills'] as num?)?.toDouble() ?? 0.0,
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
