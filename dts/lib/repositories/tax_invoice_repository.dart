import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tax_invoice_model.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

final taxInvoiceRepositoryProvider = Provider<TaxInvoiceRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TaxInvoiceRepository(apiService);
});

class TaxInvoicesResponse {
  final List<TaxInvoiceModel> taxInvoices;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  TaxInvoicesResponse({
    required this.taxInvoices,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class TaxInvoiceRepository {
  final ApiService _apiService;

  TaxInvoiceRepository(this._apiService);

  Future<TaxInvoicesResponse> getTaxInvoices({
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
        ApiConstants.taxInvoices,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final invoicesRaw = data['taxInvoices'] ?? data['invoices'] as List; // fallback just in case
      final invoices = (invoicesRaw as List)
          .map((e) => TaxInvoiceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>;

      return TaxInvoicesResponse(
        taxInvoices: invoices,
        page: pagination['page'] ?? page,
        limit: pagination['limit'] ?? limit,
        total: pagination['total'] ?? 0,
        totalPages: pagination['totalPages'] ?? 1,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<TaxInvoiceModel> getTaxInvoiceById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.taxInvoices}/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      return TaxInvoiceModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<TaxInvoiceModel> createTaxInvoice({
    required TaxInvoiceModel taxInvoice,
  }) async {
    try {
      final map = <String, dynamic>{
        'taxInvoice': taxInvoice.toJson(),
      };

      final response = await _apiService.post(
        ApiConstants.taxInvoices,
        data: map,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return TaxInvoiceModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<TaxInvoiceModel> updateTaxInvoice({
    required String id,
    required TaxInvoiceModel taxInvoice,
  }) async {
    try {
      final map = <String, dynamic>{
        'taxInvoice': taxInvoice.toJson(),
      };

      final response = await _apiService.put(
        '${ApiConstants.taxInvoices}/$id',
        data: map,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return TaxInvoiceModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<TaxInvoiceModel> updatePaymentStatus({
    required String id,
    required double amountReceived,
    required DateTime paymentDate,
  }) async {
    try {
      final map = <String, dynamic>{
        'amountReceived': amountReceived,
        'paymentDate': paymentDate.toIso8601String(),
      };

      final response = await _apiService.patch(
        '${ApiConstants.taxInvoices}/$id/payment',
        data: map,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return TaxInvoiceModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTaxInvoice(String id) async {
    try {
      await _apiService.delete('${ApiConstants.taxInvoices}/$id');
    } catch (e) {
      rethrow;
    }
  }
}
