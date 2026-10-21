import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../main_navigation.dart';

/// Màn hình khởi động Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Chờ hiệu ứng khởi động, đồng thời kiểm tra token (A8) để chọn màn hình đầu tiên
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    final results = await Future.wait([
      auth.restoreSession(),
      Future<void>.delayed(const Duration(milliseconds: 2200)),
    ]);
    if (!mounted) return;
    final loggedIn = results.first as bool;
    final Widget next = loggedIn
        ? const MainNavigationScreen()
        : const LoginScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => next,
        transitionsBuilder: (context, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1B4B), // Deep Indigo
              AppColors.primary, // Electric Indigo
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(0, 10),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 64.0,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              FadeTransition(
                opacity: _opacityAnimation,
                child: Column(
                  children: [
                    Text(
                      'EDU LEARNER',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Học tập thông minh & Cá nhân hóa',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
              const SizedBox(height: 24.0),
              Text(
                'Phiên bản 1.0 — KLTN KLCN044',
                style: AppTypography.captionTiny.copyWith(
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
