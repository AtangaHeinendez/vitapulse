import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';

/// Animated Lottie pulse intro shown right after the native splash.
/// Hands off to onboarding on first run, otherwise straight to home.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      _timer = Timer(
        Duration(milliseconds: reduceMotion ? 200 : 1700),
        _continue,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _continue() {
    if (!mounted) return;
    // The router's redirect sends us to onboarding, auth, or home.
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Lottie.asset(
                    'assets/lottie/pulse.json',
                    repeat: false,
                    animate: !reduceMotion,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'VitaPulse',
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: .5,
                  ),
                )
                    .animate(target: reduceMotion ? 0 : 1)
                    .fadeIn(delay: 350.ms, duration: 600.ms)
                    .slideY(begin: .25, curve: Curves.easeOutCubic),
                const SizedBox(height: 6),
                Text(
                  'Your health, in rhythm',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: .85),
                  ),
                )
                    .animate(target: reduceMotion ? 0 : 1)
                    .fadeIn(delay: 550.ms, duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
