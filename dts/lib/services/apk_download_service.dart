import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ApkDownloadService {
  final Dio _dio = Dio();

  /// Downloads the APK to the temporary directory and returns its local file path.
  Future<String> downloadApk({
    required String apkUrl,
    required void Function(double progress) onProgress,
  }) async {
    try {
      print("Starting APK Download from URL: $apkUrl");

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/dts_update.apk';
      print("Saving APK to: $filePath");

      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        apkUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );

      print("Download completed.");
      if (!await file.exists()) {
        throw Exception("Downloaded APK file not found at $filePath");
      }

      final fileSize = await file.length();
      print("Downloaded file size: $fileSize bytes");
      return filePath;
    } catch (e) {
      print("Error in downloadApk: $e");
      rethrow;
    }
  }

  /// Launches the Android Package Installer to install the APK at the given path.
  Future<void> installApk(String filePath) async {
    try {
      print("Launching Package Installer for file: $filePath");
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("APK file not found for installation: $filePath");
      }

      final result = await OpenFilex.open(filePath);
      print("OpenFilex Result Type: ${result.type}");
      print("OpenFilex Result Message: ${result.message}");

      if (result.type != ResultType.done) {
        throw Exception("Failed to open Package Installer: ${result.message}");
      }
    } catch (e) {
      print("Error in installApk: $e");
      rethrow;
    }
  }
}