import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The dashboard hero: today's steps as a sweeping progress ring.
class StepsRingCard extends StatelessWidget {
  const StepsRingCard({
    super.key,
    required this.steps,
    required this.goal,
    this.onTap,
  });

  final int steps;
  final int goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final progress = goal <= 0 ? 0.0 : (steps / goal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.metricWash(AppColors.steps,
              brightness: theme.brightness),
          borderRadius: BorderRadius.circular(28),
          boxShadow: softShadow(context),
        ),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduceMotion ? progress : 0, end: progress),
              duration: Duration(milliseconds: reduceMotion ? 0 : 1100),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => SizedBox(
                width: 132,
                height: 132,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: value,
                    color: AppColors.steps,
                    track: AppColors.steps.withValues(alpha: .15),
                  ),
                  child: Center(
                    child: Hero(
                      tag: 'metric-steps',
                      child: Icon(Icons.directions_walk_rounded,
                          color: AppColors.steps, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Steps today',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: .65),
                      )),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                        begin: reduceMotion ? steps.toDouble() : 0,
                        end: steps.toDouble()),
                    duration:
                        Duration(milliseconds: reduceMotion ? 0 : 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Text(
                      NumberFormat.decimalPattern().format(value.round()),
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'of ${NumberFormat.decimalPattern().format(goal)} goal · '
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: .55),
                    ),
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

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2 + 1);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(inset, 0, 2 * pi, false, trackPaint);

    if (progress > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: [color.withValues(alpha: .55), color],
          transform: const GradientRotation(-pi / 2),
        ).createShader(rect);
      canvas.drawArc(inset, -pi / 2, 2 * pi * progress, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
