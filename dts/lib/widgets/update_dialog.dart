import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/app_version.dart';

Future<bool> showUpdateDialog({
  required BuildContext context,
  required PlatformVersion version,
}) async {
  final isWindows = !kIsWeb && Platform.isWindows;
  final isUrlAvailable = version.downloadUrl != null && version.downloadUrl!.trim().isNotEmpty;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: !version.forceUpdate,
    builder: (context) {
      return PopScope(
        canPop: !version.forceUpdate,
        child: AlertDialog(
          title: Text(
            version.forceUpdate
                ? "Update Required"
                : "Update Available",
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Version ${version.version}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              if (version.releaseNotes.isNotEmpty) ...[
                const Text(
                  "What's New",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                ...version.releaseNotes.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text("• $e"),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (isWindows && !isUrlAvailable)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Update available, but the Windows installer is not currently available.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            if (!version.forceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text("Later"),
              ),

            ElevatedButton(
              onPressed: (isWindows && !isUrlAvailable)
                  ? null
                  : () {
                      Navigator.pop(context, true);
                    },
              child: const Text("Update"),
            ),
          ],
        ),
      );
    },
  );

  return result ?? false;
}