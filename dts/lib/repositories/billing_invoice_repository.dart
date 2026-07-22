import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/billing_invoice_model.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

final billingInvoiceRepositoryProvider = Provider<BillingInvoiceRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return BillingInvoiceRepository(apiService);
});

class BillingInvoicesResponse {
  final List<BillingInvoiceModel> billingInvoices;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  BillingInvoicesResponse({
    required this.billingInvoices,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class BillingInvoiceRepository {
  final ApiService _apiService;

  BillingInvoiceRepository(this._apiService);

  Future<BillingInvoicesResponse> getBillingInvoices({
    int page = 1,
    int limit = 10,
    String search = '',
    String dateFrom = '',
    String dateTo = '',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'search': search,
      };
      if (dateFrom.isNotEmpty) {
        queryParams['dateFrom'] = dateFrom;
      }
      if (dateTo.isNotEmpty) {
        queryParams['dateTo'] = dateTo;
      }

      final response = await _apiService.get(
        ApiConstants.billingInvoices,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final invoicesRaw = data['billingInvoices'] ?? data['invoices'] as List;
      final invoices = (invoicesRaw as List)
          .map((e) => BillingInvoiceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>;

      return BillingInvoicesResponse(
        billingInvoices: invoices,
        page: pagination['page'] ?? page,
        limit: pagination['limit'] ?? limit,
        total: pagination['total'] ?? 0,
        totalPages: pagination['totalPages'] ?? 1,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<BillingInvoiceModel> getBillingInvoiceById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.billingInvoices}/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      return BillingInvoiceModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<BillingInvoiceModel> createBillingInvoice({
    required BillingInvoiceModel billingInvoice,
  }) async {
    try {
      final map = <String, dynamic>{
        'billingInvoice': billingInvoice.toJson(),
      };

      final response = await _apiService.post(
        ApiConstants.billingInvoices,
        data: map,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return BillingInvoiceModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<BillingInvoiceModel> updateBillingInvoice({
    required String id,
    required BillingInvoiceModel billingInvoice,
  }) async {
    try {
      final map = <String, dynamic>{
        'billingInvoice': billingInvoice.toJson(),
      };

      final response = await _apiService.put(
        '${ApiConstants.billingInvoices}/$id',
        data: map,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return BillingInvoiceModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBillingInvoice(String id) async {
    try {
      await _apiService.delete('${ApiConstants.billingInvoices}/$id');
    } catch (e) {
      rethrow;
    }
  }
}
