import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CustomerRepository(apiService);
});

class CustomersResponse {
  final List<CustomerModel> customers;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  CustomersResponse({
    required this.customers,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class CustomerRepository {
  final ApiService _apiService;

  CustomerRepository(this._apiService);

  Future<CustomersResponse> getCustomers({
    int page = 1,
    int limit = 10,
    String search = '',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'search': search,
      };

      final response = await _apiService.get(
        ApiConstants.customers,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final customersRaw = data['customers'] as List;
      final customers = customersRaw
          .map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>;

      return CustomersResponse(
        customers: customers,
        page: pagination['page'] ?? page,
        limit: pagination['limit'] ?? limit,
        total: pagination['total'] ?? 0,
        totalPages: pagination['totalPages'] ?? 1,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.customers}/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      return CustomerModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }
}
