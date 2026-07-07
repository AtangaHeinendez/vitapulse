import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Rounded gradient-washed card used in the dashboard grid.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.value,
    this.unit,
    this.subtitle,
    this.heroTag,
    this.sparkline,
    this.trailing,
    this.onTap,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String value;
  final String? unit;
  final String? subtitle;
  final String? heroTag;
  final List<double>? sparkline;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget iconBox = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: accent, size: 21),
    );
    if (heroTag != null) iconBox = Hero(tag: heroTag!, child: iconBox);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.metricWash(accent, brightness: theme.brightness),
          borderRadius: BorderRadius.circular(24),
          boxShadow: softShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                iconBox,
                const Spacer(),
                ?trailing,
              ],
            ),
            const Spacer(),
            if (sparkline != null && sparkline!.length >= 2) ...[
              SizedBox(
                height: 26,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SparklinePainter(sparkline!, accent),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text.rich(
              TextSpan(
                text: value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: .5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle ?? title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: .55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - minV) / span) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: .25), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}
