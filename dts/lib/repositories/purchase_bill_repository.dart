import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase_bill_model.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

final purchaseBillRepositoryProvider = Provider<PurchaseBillRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PurchaseBillRepository(apiService);
});

class PurchaseBillsResponse {
  final List<PurchaseBillModel> purchaseBills;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PurchaseBillsResponse({
    required this.purchaseBills,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class PurchaseBillRepository {
  final ApiService _apiService;

  PurchaseBillRepository(this._apiService);

  Future<PurchaseBillsResponse> getPurchaseBills({
    int page = 1,
    int limit = 10,
    String search = '',
    String status = '',
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

      final response = await _apiService.get(
        ApiConstants.purchaseBills,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final billsRaw = data['purchaseBills'] as List;
      final bills = billsRaw
          .map((e) => PurchaseBillModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>;

      return PurchaseBillsResponse(
        purchaseBills: bills,
        page: pagination['page'] ?? page,
        limit: pagination['limit'] ?? limit,
        total: pagination['total'] ?? 0,
        totalPages: pagination['totalPages'] ?? 1,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<PurchaseBillModel> getPurchaseBillById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.purchaseBills}/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      return PurchaseBillModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<PurchaseBillModel> createPurchaseBill({
    required String vendorName,
    required double amount,
    double taxAmount = 0.0,
    String billNumber = '',
    required DateTime billDate,
    String remarks = '',
    String status = 'pending',
    required File attachmentFile,
  }) async {
    try {
      final map = <String, dynamic>{
        'vendorName': vendorName,
        'amount': amount,
        'taxAmount': taxAmount,
        'billNumber': billNumber,
        'billDate': billDate.toIso8601String(),
        'remarks': remarks,
        'status': status,
        'attachment': await MultipartFile.fromFile(
          attachmentFile.path,
          filename: attachmentFile.path.split('/').last,
        ),
      };

      final formData = FormData.fromMap(map);

      final response = await _apiService.post(
        ApiConstants.purchaseBills,
        data: formData,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return PurchaseBillModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<PurchaseBillModel> updatePurchaseBill({
    required String id,
    String? vendorName,
    double? amount,
    double? taxAmount,
    String? billNumber,
    DateTime? billDate,
    String? remarks,
    String? status,
    File? attachmentFile,
  }) async {
    try {
      final map = <String, dynamic>{};
      if (vendorName != null) map['vendorName'] = vendorName;
      if (amount != null) map['amount'] = amount;
      if (taxAmount != null) map['taxAmount'] = taxAmount;
      if (billNumber != null) map['billNumber'] = billNumber;
      if (billDate != null) map['billDate'] = billDate.toIso8601String();
      if (remarks != null) map['remarks'] = remarks;
      if (status != null) map['status'] = status;
      if (attachmentFile != null) {
        map['attachment'] = await MultipartFile.fromFile(
          attachmentFile.path,
          filename: attachmentFile.path.split('/').last,
        );
      }

      final formData = FormData.fromMap(map);

      final response = await _apiService.put(
        '${ApiConstants.purchaseBills}/$id',
        data: formData,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return PurchaseBillModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePurchaseBill(String id) async {
    try {
      await _apiService.delete('${ApiConstants.purchaseBills}/$id');
    } catch (e) {
      rethrow;
    }
  }
}
