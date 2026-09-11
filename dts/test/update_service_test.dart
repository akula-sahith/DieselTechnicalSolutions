import 'package:flutter_test/flutter_test.dart';
import 'package:dts/models/app_version.dart';

void main() {
  group('AppVersion & PlatformVersion Multi-Platform Integration Tests', () {
    test('Case 1: Parse legacy top-level backend response', () {
      final json = {
        'latestVersion': '1.1.0',
        'buildNumber': 5,
        'apkUrl': 'https://example.com/app-v1.1.0.apk',
        'forceUpdate': false,
        'releaseNotes': ['Bug fixes'],
      };

      final appVer = AppVersion.fromJson(json);

      expect(appVer.latestVersion, '1.1.0');
      expect(appVer.buildNumber, 5);
      expect(appVer.apkUrl, 'https://example.com/app-v1.1.0.apk');
      expect(appVer.forceUpdate, false);
      expect(appVer.android, isNull);
      expect(appVer.windows, isNull);
    });

    test('Case 2: Parse dual-platform backend response (Android + Windows)', () {
      final json = {
        'latestVersion': '1.2.0',
        'buildNumber': 10,
        'apkUrl': 'https://example.com/legacy-apk.apk',
        'forceUpdate': true,
        'releaseNotes': ['Global notes'],
        'android': {
          'version': '1.2.0',
          'buildNumber': 10,
          'downloadUrl': 'https://example.com/android-v1.2.0.apk',
          'forceUpdate': true,
          'releaseNotes': ['Android UI polish'],
        },
        'windows': {
          'version': '1.2.0',
          'buildNumber': 10,
          'downloadUrl': null,
          'forceUpdate': false,
          'releaseNotes': ['Windows Desktop table view'],
        },
      };

      final appVer = AppVersion.fromJson(json);

      expect(appVer.android, isNotNull);
      expect(appVer.android!.version, '1.2.0');
      expect(appVer.android!.downloadUrl, 'https://example.com/android-v1.2.0.apk');
      expect(appVer.android!.forceUpdate, true);

      expect(appVer.windows, isNotNull);
      expect(appVer.windows!.version, '1.2.0');
      expect(appVer.windows!.downloadUrl, isNull);
      expect(appVer.windows!.forceUpdate, false);
    });

    test('Case 3: Windows NEVER inherits Android APK URL when Windows downloadUrl is null', () {
      final json = {
        'latestVersion': '1.2.0',
        'buildNumber': 10,
        'apkUrl': 'https://example.com/android-v1.2.0.apk',
        'forceUpdate': true,
        'releaseNotes': ['Notes'],
        'windows': {
          'version': '1.2.0',
          'buildNumber': 10,
          'downloadUrl': null,
          'forceUpdate': false,
          'releaseNotes': ['Windows notes'],
        },
      };

      final appVer = AppVersion.fromJson(json);
      expect(appVer.windows!.downloadUrl, isNull);
    });

    test('Case 4: Independent forceUpdate between Android and Windows', () {
      final json = {
        'latestVersion': '1.3.0',
        'buildNumber': 15,
        'apkUrl': 'https://example.com/android.apk',
        'forceUpdate': true,
        'releaseNotes': [],
        'android': {
          'version': '1.3.0',
          'buildNumber': 15,
          'downloadUrl': 'https://example.com/android.apk',
          'forceUpdate': true,
          'releaseNotes': [],
        },
        'windows': {
          'version': '1.3.0',
          'buildNumber': 15,
          'downloadUrl': 'https://example.com/dts-v1.3.0.msix',
          'forceUpdate': false,
          'releaseNotes': [],
        },
      };

      final appVer = AppVersion.fromJson(json);
      expect(appVer.android!.forceUpdate, isTrue);
      expect(appVer.windows!.forceUpdate, isFalse);
    });
  });
}
