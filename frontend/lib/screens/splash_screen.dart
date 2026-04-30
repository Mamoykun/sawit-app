import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/sawit_logo.dart';
import '../widgets/organic_background.dart';
import 'login_screen.dart';
import 'lahan_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2000), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    bool isLoggedIn = false;
    try {
      final hasToken = await ApiService().isLoggedIn();
      if (hasToken) {
        await ApiService().getProfile();
        isLoggedIn = true;
      }
    } catch (_) {
      isLoggedIn = false;
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            isLoggedIn ? const LahanScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
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
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary2, AppColors.primary3],
        ),
      ),
      child: Stack(
        children: [
          const OrganicBackground(
            blobColor: Color(0xFF74C69D),
            particleColor: AppColors.goldLight,
            blobOpacity: 0.15,
            particleOpacity: 0.35,
            particleCount: 32,
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                const SawitLogo(
                  size: 96,
                  primaryColor: Color(0xFF14532D),
                  withGlow: true,
                ),
                const SizedBox(height: Spacing.xxl),
                Text('SawitKu',
                    style: AppTextStyles.hero(48, color: Colors.white)),
                const SizedBox(height: Spacing.sm),
                Text(
                  'PLATFORM MANAJEMEN KEBUN',
                  style: AppTextStyles.label(
                      color: const Color(0xFF74C69D)),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF74C69D),
                    strokeWidth: 2,
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
