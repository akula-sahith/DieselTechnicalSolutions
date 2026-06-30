import 'package:flutter/material.dart';

class DownloadProgressDialog extends StatelessWidget {
  final ValueNotifier<double> progress;

  const DownloadProgressDialog({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text("Downloading Update"),
        content: Column(
  mainAxisSize: MainAxisSize.min,
  children: [

    ValueListenableBuilder<double>(
      valueListenable: progress,
      builder: (_, value, __) {
        return LinearProgressIndicator(
          value: value,
        );
      },
    ),

    const SizedBox(height: 20),

    ValueListenableBuilder<double>(
      valueListenable: progress,
      builder: (_, value, __) {
        return Text(
          "${(value * 100).toStringAsFixed(0)}%",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),

    const SizedBox(height: 10),

    const Text(
      "Please wait while downloading...",
      textAlign: TextAlign.center,
    ),
  ],
),
      ),
    );
  }
}