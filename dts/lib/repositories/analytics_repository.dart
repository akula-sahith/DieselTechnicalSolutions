import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/financial_analytics_model.dart';

class AnalyticsRepository {
  final ApiService _apiService;

  AnalyticsRepository(this._apiService);

  Future<MonthlyDetailModel> getMonthlyDetail(int year, int month) async {
    final response = await _apiService.get('/dashboard/monthly-detail', queryParameters: {
      'year': year,
      'month': month,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    return MonthlyDetailModel.fromJson(data);
  }

  Future<WeekDocumentsResponse> getWeekDocuments(String startDate, String endDate) async {
    final response = await _apiService.get('/dashboard/week-documents', queryParameters: {
      'startDate': startDate,
      'endDate': endDate,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    return WeekDocumentsResponse.fromJson(data);
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AnalyticsRepository(apiService);
});
