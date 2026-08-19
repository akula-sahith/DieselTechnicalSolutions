import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery_challan_model.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

final deliveryChallanRepositoryProvider = Provider<DeliveryChallanRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DeliveryChallanRepository(apiService);
});

class DeliveryChallansResponse {
  final List<DeliveryChallanModel> deliveryChallans;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  DeliveryChallansResponse({
    required this.deliveryChallans,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class DeliveryChallanRepository {
  final ApiService _apiService;

  DeliveryChallanRepository(this._apiService);

  Future<DeliveryChallansResponse> getDeliveryChallans({
    int page = 1,
    int limit = 10,
    String search = '',
    String status = '',
    String dateFrom = '',
    String dateTo = '',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'search': search,
      };
      if (status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (dateFrom.isNotEmpty) {
        queryParams['dateFrom'] = dateFrom;
      }
      if (dateTo.isNotEmpty) {
        queryParams['dateTo'] = dateTo;
      }

      final response = await _apiService.get(
        ApiConstants.deliveryChallans,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final challansRaw = data['deliveryChallans'] as List;
      final deliveryChallans = challansRaw
          .map((e) => DeliveryChallanModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>;

      return DeliveryChallansResponse(
        deliveryChallans: deliveryChallans,
        page: pagination['page'] ?? page,
        limit: pagination['limit'] ?? limit,
        total: pagination['total'] ?? 0,
        totalPages: pagination['totalPages'] ?? 1,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<DeliveryChallanModel> getDeliveryChallanById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.deliveryChallans}/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      return DeliveryChallanModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<DeliveryChallanModel> createDeliveryChallan({
    required DeliveryChallanModel deliveryChallan,
  }) async {
    try {
      final map = <String, dynamic>{
        'deliveryChallan': deliveryChallan.toJson(),
      };

      final response = await _apiService.post(
        ApiConstants.deliveryChallans,
        data: map,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return DeliveryChallanModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<DeliveryChallanModel> updateDeliveryChallan({
    required String id,
    required DeliveryChallanModel deliveryChallan,
  }) async {
    try {
      final map = <String, dynamic>{
        'deliveryChallan': deliveryChallan.toJson(),
      };

      final response = await _apiService.put(
        '${ApiConstants.deliveryChallans}/$id',
        data: map,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return DeliveryChallanModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<DeliveryChallanModel> convertEstimateToDeliveryChallan({
    required String estimateId,
    required DeliveryChallanModel deliveryChallan,
  }) async {
    try {
      final map = <String, dynamic>{
        'deliveryChallan': deliveryChallan.toJson(),
      };

      final response = await _apiService.post(
        '${ApiConstants.estimates}/$estimateId/convert-to-delivery-challan',
        data: map,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return DeliveryChallanModel.fromJson(data['deliveryChallan']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDeliveryChallan(String id) async {
    try {
      await _apiService.delete('${ApiConstants.deliveryChallans}/$id');
    } catch (e) {
      rethrow;
    }
  }
}
