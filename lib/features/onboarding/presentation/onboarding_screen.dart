import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class _PageData {
  const _PageData({
    required this.accent,
    required this.icon,
    required this.chips,
    required this.title,
    required this.body,
  });

  final Color accent;
  final IconData icon;
  final List<(IconData, Color)> chips;
  final String title;
  final String body;
}

const _pages = [
  _PageData(
    accent: AppColors.teal,
    icon: Icons.favorite_rounded,
    chips: [
      (Icons.directions_walk_rounded, AppColors.steps),
      (Icons.monitor_heart_rounded, AppColors.heartRate),
      (Icons.bedtime_rounded, AppColors.sleep),
    ],
    title: 'All your health\nin one place',
    body:
        'Steps, heart rate, sleep, SpO₂ and more — synced from your Galaxy Watch through Health Connect.',
  ),
  _PageData(
    accent: AppColors.spo2,
    icon: Icons.insights_rounded,
    chips: [
      (Icons.bloodtype_rounded, AppColors.bloodPressure),
      (Icons.local_fire_department_rounded, AppColors.calories),
      (Icons.monitor_weight_rounded, AppColors.weight),
    ],
    title: 'See the trends\nthat matter',
    body:
        'Beautiful day, week and month charts for every metric, with goals that keep you moving.',
  ),
  _PageData(
    accent: AppColors.calories,
    icon: Icons.notifications_active_rounded,
    chips: [
      (Icons.water_drop_rounded, AppColors.water),
      (Icons.favorite_rounded, AppColors.heartRate),
      (Icons.alarm_rounded, AppColors.teal),
    ],
    title: 'Gentle nudges,\nbetter habits',
    body:
        'Hydration and blood-pressure reminders, quick water logging, and a dashboard that celebrates progress.',
  ),
];

/// Three-page animated onboarding, shown on first run only.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(prefsServiceProvider).setOnboardingComplete();
    // Router redirect decides what comes next (auth or home).
    if (mounted) context.go(Routes.home);
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _OnboardPage(data: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? _pages[_page].accent
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _pages[_page].accent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _next,
                    child: Text(isLast ? 'Get started' : 'Next'),
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

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({required this.data});

  final _PageData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      data.accent.withValues(alpha: .22),
                      data.accent.withValues(alpha: .06),
                    ],
                  ),
                ),
              ),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.accent,
                  boxShadow: [
                    BoxShadow(
                      color: data.accent.withValues(alpha: .35),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(data.icon, size: 64, color: Colors.white),
              ),
              for (final (i, chip) in data.chips.indexed)
                Align(
                  alignment: [
                    const Alignment(-.78, -.55),
                    const Alignment(.82, -.25),
                    const Alignment(-.6, .72),
                  ][i],
                  child: _MetricChip(icon: chip.$1, color: chip.$2, index: i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(height: 1.15),
              ),
              const SizedBox(height: 14),
              Text(
                data.body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: .65),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // Scroll when vertical space is tight (small phones, landscape),
    // center when there is room.
    final page = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: content),
        ),
      ),
    );

    if (reduceMotion) return page;
    return page
        .animate()
        .fadeIn(duration: 450.ms)
        .slideY(begin: .06, curve: Curves.easeOutCubic);
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.color, required this.index});

  final IconData icon;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final chip = Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: softShadow(context),
      ),
      child: Icon(icon, color: color, size: 28),
    );
    if (reduceMotion) return chip;
    return chip
        .animate(delay: (250 + index * 140).ms)
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(.6, .6), curve: Curves.easeOutBack);
  }
}
