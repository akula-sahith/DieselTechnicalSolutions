import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ApkDownloadService {
  final Dio _dio = Dio();

  Future<void> downloadAndInstall({
    required String apkUrl,
    required void Function(double progress) onProgress,
  }) async {
    print("APK URL: $apkUrl");

    final directory = await getApplicationDocumentsDirectory();
    print("Directory: ${directory.path}");

    final filePath = '${directory.path}/dts_update.apk';
    print("Saving to: $filePath");

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

    print("Download completed");
    print("File Exists: ${await file.exists()}");

    if (await file.exists()) {
      print("File Size: ${await file.length()} bytes");
    }

    final result = await OpenFilex.open(filePath);

    print("OpenFile Result: ${result.type}");
    print("OpenFile Message: ${result.message}");
  }
}