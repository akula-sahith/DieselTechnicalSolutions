import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_version.dart';
import 'api_service.dart';
import '../core/constants/api_constants.dart';
import 'update_service.dart';
import 'apk_download_service.dart';

final versionServiceProvider = Provider<VersionService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VersionService(apiService);
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  final versionService = ref.watch(versionServiceProvider);
  return UpdateService(versionService);
});

final apkDownloadServiceProvider = Provider<ApkDownloadService>((ref) {
  return ApkDownloadService();
});

class VersionService {
  final ApiService _apiService;

  VersionService(this._apiService);

  Future<AppVersion> getLatestVersion() async {
    final response = await _apiService.get(ApiConstants.appVersions);

    return AppVersion.fromJson(response.data['data']);
  }
}