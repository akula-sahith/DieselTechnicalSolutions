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

      final installedBuild =
          int.tryParse(packageInfo.buildNumber) ?? 0;

      if (serverVersion.buildNumber > installedBuild) {
        return serverVersion;
      }

      return null;
    } catch (e) {
      // Ignore update failures and continue normally
      return null;
    }
  }
}