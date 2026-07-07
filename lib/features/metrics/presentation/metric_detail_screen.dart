import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../application/detail_providers.dart';
import 'entry_sheets.dart';

class MetricDetailSpec {
  const MetricDetailSpec(this.key, this.title, this.icon, this.accent,
      {this.entry});

  final String key;
  final String title;
  final IconData icon;
  final Color accent;
  final ManualEntryKind? entry;

  static const all = <String, MetricDetailSpec>{
    'steps': MetricDetailSpec(
        'steps', 'Steps', Icons.directions_walk_rounded, AppColors.steps),
    'heart_rate': MetricDetailSpec('heart_rate', 'Heart rate',
        Icons.monitor_heart_rounded, AppColors.heartRate),
    'sleep_session': MetricDetailSpec(
        'sleep_session', 'Sleep', Icons.bedtime_rounded, AppColors.sleep),
    'blood_pressure': MetricDetailSpec('blood_pressure', 'Blood pressure',
        Icons.bloodtype_rounded, AppColors.bloodPressure,
        entry: ManualEntryKind.bloodPressure),
    'spo2': MetricDetailSpec(
        'spo2', 'SpO₂', Icons.bubble_chart_rounded, AppColors.spo2),
    'water_intake': MetricDetailSpec('water_intake', 'Water',
        Icons.water_drop_rounded, AppColors.water,
        entry: ManualEntryKind.water),
    'calories_burned': MetricDetailSpec('calories_burned', 'Calories',
        Icons.local_fire_department_rounded, AppColors.calories),
    'weight': MetricDetailSpec(
        'weight', 'Weight', Icons.monitor_weight_rounded, AppColors.weight,
        entry: ManualEntryKind.weight),
  };
}

class MetricDetailScreen extends ConsumerStatefulWidget {
  const MetricDetailScreen({super.key, required this.metricKey});

  final String metricKey;

  @override
  ConsumerState<MetricDetailScreen> createState() =>
      _MetricDetailScreenState();
}

class _MetricDetailScreenState extends ConsumerState<MetricDetailScreen> {
  ChartRange _range = ChartRange.week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = MetricDetailSpec.all[widget.metricKey];
    if (spec == null) {
      return const Scaffold(body: Center(child: Text('Unknown metric')));
    }
    final detail =
        ref.watch(metricDetailProvider(widget.metricKey, _range));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'metric-${spec.key}',
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: spec.accent.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(spec.icon, color: spec.accent, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Text(spec.title),
          ],
        ),
      ),
      floatingActionButton: spec.entry == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: spec.accent,
              foregroundColor: Colors.white,
              onPressed: () => showManualEntrySheet(context, spec.entry!),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          Center(
            child: SegmentedButton<ChartRange>(
              segments: const [
                ButtonSegment(value: ChartRange.day, label: Text('Day')),
                ButtonSegment(value: ChartRange.week, label: Text('Week')),
                ButtonSegment(value: ChartRange.month, label: Text('Month')),
              ],
              selected: {_range},
              onSelectionChanged: (s) => setState(() => _range = s.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 18),
          detail.when(
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SizedBox(
              height: 200,
              child: Center(child: Text('Could not load data: $e')),
            ),
            data: (d) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 260,
                  padding: const EdgeInsets.fromLTRB(12, 24, 20, 8),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: softShadow(context),
                  ),
                  child: d.points.isEmpty
                      ? Center(
                          child: Text(
                            'No data in this range yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: .5),
                            ),
                          ),
                        )
                      : _Chart(spec: spec, data: d, range: _range),
                ).animate().fadeIn(duration: 350.ms),
                const SizedBox(height: 16),
                _StatsRow(spec: spec, data: d),
                const SizedBox(height: 22),
                if (d.history.isNotEmpty) ...[
                  Text('History', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  for (final (i, h) in d.history.indexed)
                    _HistoryTile(entry: h, spec: spec, index: i),
                ],
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.spec, required this.data, required this.range});

  final MetricDetailSpec spec;
  final DetailData data;
  final ChartRange range;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: .45),
      fontSize: 11,
    );

    final maxX = range == ChartRange.day
        ? 24.0
        : (range == ChartRange.week ? 6.0 : 29.0);

    Widget bottomTitle(double value, TitleMeta meta) {
      String? text;
      if (range == ChartRange.day) {
        final h = value.round();
        if (h % 6 == 0 && h <= 24) text = '${h}h';
      } else {
        text = data.labels[value.round()];
      }
      if (text == null) return const SizedBox.shrink();
      return SideTitleWidget(
        meta: meta,
        child: Text(text, style: labelStyle),
      );
    }

    final titles = FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          getTitlesWidget: (v, meta) => SideTitleWidget(
            meta: meta,
            child: Text(meta.formattedValue, style: labelStyle),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          interval: range == ChartRange.day ? 1 : 1,
          getTitlesWidget: bottomTitle,
        ),
      ),
    );

    final grid = FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (v) => FlLine(
        color: theme.colorScheme.onSurface.withValues(alpha: .06),
        strokeWidth: 1,
      ),
    );

    if (isCumulative(spec.key)) {
      return BarChart(
        BarChartData(
          gridData: grid,
          titlesData: titles,
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => spec.accent,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                rod.toY.round().toString(),
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          barGroups: [
            for (final p in data.points)
              BarChartGroupData(
                x: p.x.round(),
                barRods: [
                  BarChartRodData(
                    toY: p.y,
                    width: range == ChartRange.month ? 6 : 10,
                    borderRadius: BorderRadius.circular(4),
                    color: spec.accent,
                  ),
                ],
              ),
          ],
          maxY: null,
        ),
      );
    }

    LineChartBarData line(List<FlSpot> spots, Color color,
            {bool filled = true}) =>
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: .25,
          preventCurveOverShooting: true,
          barWidth: 3,
          color: color,
          dotData: FlDotData(show: spots.length <= 14),
          belowBarData: BarAreaData(
            show: filled,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: .22),
                color.withValues(alpha: 0)
              ],
            ),
          ),
        );

    final primarySpots = [for (final p in data.points) FlSpot(p.x, p.y)];
    final diaSpots = [
      for (final p in data.points)
        if (p.y2 != null) FlSpot(p.x, p.y2!),
    ];
    final isBp = spec.key == 'blood_pressure';

    return LineChart(
      LineChartData(
        gridData: grid,
        titlesData: titles,
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxX,
        rangeAnnotations: isBp
            ? RangeAnnotations(horizontalRangeAnnotations: [
                HorizontalRangeAnnotation(
                  y1: 90,
                  y2: 120,
                  color: AppColors.steps.withValues(alpha: .08),
                ),
              ])
            : null,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => spec.accent,
          ),
        ),
        lineBarsData: [
          line(primarySpots, spec.accent),
          if (isBp && diaSpots.isNotEmpty)
            line(diaSpots, AppColors.bloodPressure.withValues(alpha: .45),
                filled: false),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.spec, required this.data});

  final MetricDetailSpec spec;
  final DetailData data;

  String _fmt(double? v) {
    if (v == null) return '—';
    return v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(String label, double? v) => Expanded(
          child: Column(
            children: [
              Text(_fmt(v),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: spec.accent)),
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .5),
                  )),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadow(context),
      ),
      child: Row(
        children: [
          cell('Min', data.min),
          cell('Average', data.avg),
          cell('Max', data.max),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile(
      {required this.entry, required this.spec, required this.index});

  final HistoryEntry entry;
  final MetricDetailSpec spec;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final tile = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(spec.icon, size: 18, color: spec.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              DateFormat.MMMEd().add_Hm().format(entry.when),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (entry.source != 'health_connect')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                entry.source,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: .4),
                ),
              ),
            ),
          Text(entry.display,
              style: theme.textTheme.titleSmall?.copyWith(color: spec.accent)),
        ],
      ),
    );
    if (reduceMotion || index > 12) return tile;
    return tile
        .animate(delay: (30 * index).ms)
        .fadeIn(duration: 250.ms)
        .slideY(begin: .06);
  }
}
