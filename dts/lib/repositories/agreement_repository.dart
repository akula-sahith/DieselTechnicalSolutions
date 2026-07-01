import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agreement_model.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

final agreementRepositoryProvider = Provider<AgreementRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AgreementRepository(apiService);
});

class AgreementsResponse {
  final List<AgreementModel> agreements;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  AgreementsResponse({
    required this.agreements,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class AgreementRepository {
  final ApiService _apiService;

  AgreementRepository(this._apiService);

  Future<AgreementsResponse> getAgreements({
    int page = 1,
    int limit = 10,
    String search = '',
    String documentType = '',
    String status = '',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'search': search,
      };
      if (documentType.isNotEmpty) {
        queryParams['documentType'] = documentType;
      }
      if (status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _apiService.get(
        ApiConstants.agreements,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final agreementsRaw = data['agreements'] as List;
      final agreements = agreementsRaw
          .map((e) => AgreementModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>;

      return AgreementsResponse(
        agreements: agreements,
        page: pagination['page'] ?? page,
        limit: pagination['limit'] ?? limit,
        total: pagination['total'] ?? 0,
        totalPages: pagination['totalPages'] ?? 1,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<AgreementModel> getAgreementById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.agreements}/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      return AgreementModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<AgreementModel> createAgreement({
    required AgreementModel agreement,
    File? signatureFile,
  }) async {
    try {
      final map = <String, dynamic>{
        'agreement': agreement.toJsonString(),
      };

      if (signatureFile != null) {
        map['customerSignature'] = await MultipartFile.fromFile(
          signatureFile.path,
          filename: 'signature.png',
        );
      }

      final formData = FormData.fromMap(map);

      final response = await _apiService.post(
        ApiConstants.agreements,
        data: formData,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return AgreementModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<AgreementModel> updateAgreement({
    required String id,
    required AgreementModel agreement,
    File? signatureFile,
  }) async {
    try {
      final map = <String, dynamic>{
        'agreement': agreement.toJsonString(),
      };

      if (signatureFile != null) {
        map['customerSignature'] = await MultipartFile.fromFile(
          signatureFile.path,
          filename: 'signature.png',
        );
      }

      final formData = FormData.fromMap(map);

      final response = await _apiService.put(
        '${ApiConstants.agreements}/$id',
        data: formData,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return AgreementModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAgreement(String id) async {
    try {
      await _apiService.delete('${ApiConstants.agreements}/$id');
    } catch (e) {
      rethrow;
    }
  }
}
