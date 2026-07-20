import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estimate_model.dart';
import '../models/tax_invoice_model.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

final estimateRepositoryProvider = Provider<EstimateRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return EstimateRepository(apiService);
});

class EstimatesResponse {
  final List<EstimateModel> estimates;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  EstimatesResponse({
    required this.estimates,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class EstimateRepository {
  final ApiService _apiService;

  EstimateRepository(this._apiService);

  Future<EstimatesResponse> getEstimates({
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
        ApiConstants.estimates,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final estimatesRaw = data['estimates'] as List;
      final estimates = estimatesRaw
          .map((e) => EstimateModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>;

      return EstimatesResponse(
        estimates: estimates,
        page: pagination['page'] ?? page,
        limit: pagination['limit'] ?? limit,
        total: pagination['total'] ?? 0,
        totalPages: pagination['totalPages'] ?? 1,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<EstimateModel> getEstimateById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.estimates}/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      return EstimateModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<EstimateModel> createEstimate({
    required EstimateModel estimate,
  }) async {
    try {
      // Create request map
      final map = <String, dynamic>{
        'estimate': estimate.toJson(),
      };

      // Since estimate might contain signatures later, we use JSON here.
      // If there are files (like signature URLs to be uploaded), they need FormData.
      // Assuming signatures might be uploaded separately or as base64/files.
      // We will send JSON payload for Estimates as per the API reference unless we have files.
      // The API reference states Request Body (multipart/form-data or JSON).
      
      final response = await _apiService.post(
        ApiConstants.estimates,
        data: map, // Dio will automatically serialize Map to JSON
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return EstimateModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<EstimateModel> updateEstimate({
    required String id,
    required EstimateModel estimate,
  }) async {
    try {
      final map = <String, dynamic>{
        'estimate': estimate.toJson(),
      };

      final response = await _apiService.put(
        '${ApiConstants.estimates}/$id',
        data: map,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return EstimateModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<TaxInvoiceModel> convertToInvoice({
    required String estimateId,
    required TransportationDetails transportationDetails,
  }) async {
    try {
      final map = <String, dynamic>{
        'taxInvoice': {
          'transportationDetails': transportationDetails.toJson(),
        },
      };

      final response = await _apiService.post(
        '${ApiConstants.estimates}/$estimateId/convert-to-invoice',
        data: map,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      // The endpoint returns { estimate: {...}, taxInvoice: {...} }
      return TaxInvoiceModel.fromJson(data['taxInvoice']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEstimate(String id) async {
    try {
      await _apiService.delete('${ApiConstants.estimates}/$id');
    } catch (e) {
      rethrow;
    }
  }
}
