import 'package:flutter/material.dart';
import '../models/app_version.dart';

Future<bool> showUpdateDialog({
  required BuildContext context,
  required AppVersion version,
}) async {
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
                "Version ${version.latestVersion}",
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
              ],
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
              onPressed: () {
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