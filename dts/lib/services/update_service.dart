import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_version.dart';
import 'version_service.dart';

class UpdateService {
  final VersionService _versionService;

  UpdateService(this._versionService);

  Future<AppVersion?> checkForUpdate() async {
    try {
      final serverVersion = await _versionService.getLatestVersion();

      final packageInfo = await PackageInfo.fromPlatform();

      final installedBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      final installedVersion = packageInfo.version;

      if (_isUpdateAvailable(serverVersion.latestVersion, serverVersion.buildNumber, installedVersion, installedBuild)) {
        return serverVersion;
      }

      return null;
    } catch (e) {
      // Ignore update failures and continue normally
      return null;
    }
  }

  bool _isUpdateAvailable(String serverVersion, int serverBuild, String installedVersion, int installedBuild) {
    if (serverBuild > installedBuild) {
      return true;
    }
    if (serverBuild < installedBuild) {
      // Installed build is strictly newer than server build
      return false;
    }

    return _isVersionHigher(serverVersion, installedVersion);
  }

  bool _isVersionHigher(String v1, String v2) {
    try {
      final cleanV1 = v1.toLowerCase().replaceFirst('v', '').trim();
      final cleanV2 = v2.toLowerCase().replaceFirst('v', '').trim();

      final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;

      for (int i = 0; i < maxLength; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;

        if (p1 > p2) return true;
        if (p1 < p2) return false;
      }
    } catch (_) {}

    return false;
  }
}