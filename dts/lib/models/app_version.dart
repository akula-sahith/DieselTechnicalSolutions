import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformVersion {
  final String version;
  final int buildNumber;
  final String? downloadUrl;
  final bool forceUpdate;
  final List<String> releaseNotes;

  PlatformVersion({
    required this.version,
    required this.buildNumber,
    this.downloadUrl,
    required this.forceUpdate,
    required this.releaseNotes,
  });

  factory PlatformVersion.fromJson(Map<String, dynamic> json) {
    return PlatformVersion(
      version: json['version'] ?? json['latestVersion'] ?? '',
      buildNumber: (json['buildNumber'] as num?)?.toInt() ?? 0,
      downloadUrl: (json['downloadUrl'] ?? json['apkUrl']) as String?,
      forceUpdate: json['forceUpdate'] ?? false,
      releaseNotes: json['releaseNotes'] != null
          ? List<String>.from(json['releaseNotes'])
          : <String>[],
    );
  }
}

class AppVersion {
  final String latestVersion;
  final int buildNumber;
  final String apkUrl;
  final bool forceUpdate;
  final List<String> releaseNotes;

  final PlatformVersion? android;
  final PlatformVersion? windows;

  AppVersion({
    required this.latestVersion,
    required this.buildNumber,
    required this.apkUrl,
    required this.forceUpdate,
    required this.releaseNotes,
    this.android,
    this.windows,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    final legacyVersion = json['latestVersion'] ?? '';
    final legacyBuild = (json['buildNumber'] as num?)?.toInt() ?? 0;
    final legacyApkUrl = json['apkUrl'] ?? '';
    final legacyForceUpdate = json['forceUpdate'] ?? false;
    final legacyReleaseNotes = json['releaseNotes'] != null
        ? List<String>.from(json['releaseNotes'])
        : <String>[];

    PlatformVersion? androidVer;
    if (json['android'] != null && json['android'] is Map<String, dynamic>) {
      androidVer = PlatformVersion.fromJson(json['android']);
    }

    PlatformVersion? windowsVer;
    if (json['windows'] != null && json['windows'] is Map<String, dynamic>) {
      windowsVer = PlatformVersion.fromJson(json['windows']);
    }

    return AppVersion(
      latestVersion: legacyVersion,
      buildNumber: legacyBuild,
      apkUrl: legacyApkUrl,
      forceUpdate: legacyForceUpdate,
      releaseNotes: legacyReleaseNotes,
      android: androidVer,
      windows: windowsVer,
    );
  }

  /// Returns platform-specific release metadata based on running OS.
  /// Safely avoids using Android APK URL or forceUpdate flag on Windows.
  PlatformVersion getForCurrentPlatform() {
    final isWindows = !kIsWeb && Platform.isWindows;

    if (isWindows) {
      if (windows != null) {
        return windows!;
      }
      // Safe Windows fallback (NEVER use apkUrl or Android forceUpdate on Windows)
      return PlatformVersion(
        version: latestVersion,
        buildNumber: buildNumber,
        downloadUrl: null,
        forceUpdate: false,
        releaseNotes: releaseNotes,
      );
    }

    // Default to Android / Mobile platform
    if (android != null) {
      return android!;
    }

    // Fallback to legacy fields for Android
    return PlatformVersion(
      version: latestVersion,
      buildNumber: buildNumber,
      downloadUrl: apkUrl,
      forceUpdate: forceUpdate,
      releaseNotes: releaseNotes,
    );
  }
}