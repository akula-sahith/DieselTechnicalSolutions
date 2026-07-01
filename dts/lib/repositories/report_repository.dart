import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_model.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReportRepository(apiService);
});

class ReportsResponse {
  final List<ReportModel> reports;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  ReportsResponse({
    required this.reports,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}

class ReportRepository {
  final ApiService _apiService;

  ReportRepository(this._apiService);

  Future<ReportsResponse> getReports({
    int page = 1,
    int limit = 10,
    String search = '',
    String status = '',
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
        'search': search,
      };
      if (status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      final response = await _apiService.get(
        ApiConstants.reports,
        queryParameters: queryParameters,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      final reportsRaw = data['reports'] as List;
      final reports = reportsRaw
          .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>;

      return ReportsResponse(
        reports: reports,
        page: pagination['page'] ?? page,
        limit: pagination['limit'] ?? limit,
        total: pagination['total'] ?? 0,
        totalPages: pagination['totalPages'] ?? 1,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ReportModel> getReportById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.reports}/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      return ReportModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<ReportModel> createReport({
    required ReportModel report,
    required String signatureUrl,
    File? photoFile,
  }) async {
    try {
      final Map<String, dynamic> fields = {
        'report': report.toJsonString(),
        'technicianSignatureUrl': signatureUrl,
      };

      if (photoFile != null) {
        fields['customerPhoto'] = await MultipartFile.fromFile(
          photoFile.path,
          filename: 'customer.png',
        );
      }

      final formData = FormData.fromMap(fields);

      final response = await _apiService.post(
        ApiConstants.reports,
        data: formData,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return ReportModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<ReportModel> updateReport({
    required String id,
    required ReportModel report,
    required String signatureUrl,
    File? photoFile,
  }) async {
    try {
      final Map<String, dynamic> fields = {
        'report': report.toJsonString(),
        'technicianSignatureUrl': signatureUrl,
      };

      if (photoFile != null) {
        fields['customerPhoto'] = await MultipartFile.fromFile(
          photoFile.path,
          filename: 'customer.png',
        );
      }

      final formData = FormData.fromMap(fields);

      final response = await _apiService.put(
        '${ApiConstants.reports}/$id',
        data: formData,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return ReportModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      await _apiService.delete('${ApiConstants.reports}/$id');
    } catch (e) {
      rethrow;
    }
  }
}
