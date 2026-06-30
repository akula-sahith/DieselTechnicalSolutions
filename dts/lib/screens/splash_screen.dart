import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_version.dart';
import '../widgets/update_dialog.dart';
import '../services/apk_download_service.dart';
import 'package:go_router/go_router.dart';
import '../services/update_service.dart';
import '../services/version_service.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/download_progress_dialog.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  final ValueNotifier<double> _downloadProgress = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _checkAppInitialization();
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  Future<void> _checkAppInitialization() async {
    final startTime = DateTime.now();

    final UpdateService updateService = ref.read(updateServiceProvider);
    final AppVersion? update = await updateService.checkForUpdate();

    if (!mounted) return;

    if (update != null) {
      final shouldUpdate = await showUpdateDialog(
        context: context,
        version: update,
      );

      if (!mounted) return;

      if (shouldUpdate) {
        _downloadProgress.value = 0.0;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => DownloadProgressDialog(
            progress: _downloadProgress,
          ),
        );

        final ApkDownloadService downloadService = ref.read(apkDownloadServiceProvider);
        
        try {
          final filePath = await downloadService.downloadApk(
            apkUrl: update.apkUrl,
            onProgress: (progress) {
              if (mounted) {
                _downloadProgress.value = progress;
              }
            },
          );

          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          await downloadService.installApk(filePath);
          return;
        } catch (e) {
          print("Update download or install failed: $e");
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            await showDialog(
              context: context,
              builder: (errContext) => AlertDialog(
                title: const Text("Update Failed"),
                content: Text(
                  update.forceUpdate
                      ? "The required update could not be downloaded or installed. Please check your internet connection and try again."
                      : "The update could not be downloaded or installed. Continuing to the application.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(errContext),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );

            if (update.forceUpdate) {
              return;
            }
          }
        }
      }
    }

    final elapsed = DateTime.now().difference(startTime);
    const minSplashDuration = Duration(milliseconds: 3200);
    if (elapsed < minSplashDuration) {
      await Future.delayed(minSplashDuration - elapsed);
    }

    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glowing diagonal light stripes
            Positioned.fill(
              child: Stack(
                children: [
                  Positioned(
                    top: -100,
                    right: -50,
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Container(
                        width: 120,
                        height: 700,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -200,
                    right: 80,
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Container(
                        width: 60,
                        height: 700,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.05),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    left: -100,
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Container(
                        width: 180,
                        height: 500,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.06),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'app-logo',
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 260,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.settings_suggest,
                        size: 100,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 60),
                const Text(
                  'Smart Solutions for',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Powering Performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 80,
              left: 40,
              right: 40,
              child: Column(
                children: [
                  const Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          backgroundColor: const Color(0xFF1E285F), // Dark purple/blue track
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEE6C4D)), // Bright Orange indicator
                          minHeight: 4,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
