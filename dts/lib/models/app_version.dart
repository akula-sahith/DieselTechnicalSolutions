class AppVersion {
  final String latestVersion;
  final int buildNumber;
  final String apkUrl;
  final bool forceUpdate;
  final List<String> releaseNotes;

  AppVersion({
    required this.latestVersion,
    required this.buildNumber,
    required this.apkUrl,
    required this.forceUpdate,
    required this.releaseNotes,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      latestVersion: json['latestVersion'],
      buildNumber: json['buildNumber'],
      apkUrl: json['apkUrl'],
      forceUpdate: json['forceUpdate'],
      releaseNotes: List<String>.from(json['releaseNotes']),
    );
  }
}