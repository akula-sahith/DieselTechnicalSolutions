import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_version.dart';
import 'api_service.dart';
import '../core/constants/api_constants.dart';

final versionServiceProvider = Provider<VersionService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VersionService(apiService);
});

class VersionService {
  final ApiService _apiService;

  VersionService(this._apiService);

  Future<AppVersion> getLatestVersion() async {
    final response = await _apiService.get(ApiConstants.appVersions);

    return AppVersion.fromJson(response.data['data']);
  }
}