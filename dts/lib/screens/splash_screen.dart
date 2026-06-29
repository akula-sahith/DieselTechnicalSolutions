import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    Timer(const Duration(milliseconds: 3200), _checkAuthAndNavigate);
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
