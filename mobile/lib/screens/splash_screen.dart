import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await AuthService.instance.load();
    // Returning user: rotate the access token using the stored refresh token so
    // they stay signed in. A dead refresh token clears the session here.
    if (AuthService.instance.isLoggedIn) {
      await ApiService().refreshSession();
    }
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    final auth = AuthService.instance;
    Widget next;
    if (!auth.isLoggedIn) {
      next = const AuthScreen();
    } else if (!(auth.profile?.onboardingComplete ?? false)) {
      next = const OnboardingScreen();
    } else {
      next = const MainShell();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The logo badge, with a looping light "sweep" — Noor means light.
    final Widget logo = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: SvgPicture.asset(
        'assets/master/noorai-mark-white.svg',
        width: 96,
        height: 96,
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 700.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 500.ms)
        .animate(onPlay: (c) => c.repeat()) // continuous shimmer loop
        .shimmer(
          delay: 900.ms,
          duration: 2200.ms,
          color: Colors.white.withValues(alpha: 0.55),
        );

    return Scaffold(
      body: Container(
        color: NoorColors.brand,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              logo,
              const SizedBox(height: 28),
              const Text(
                'NoorAI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 450.ms, duration: 550.ms)
                  .slideY(
                      begin: 0.35,
                      end: 0,
                      delay: 450.ms,
                      duration: 650.ms,
                      curve: Curves.easeOutCubic),
              const SizedBox(height: 8),
              Text(
                "Care, made findable.",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ).animate().fadeIn(delay: 750.ms, duration: 600.ms),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ).animate().fadeIn(delay: 1100.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
