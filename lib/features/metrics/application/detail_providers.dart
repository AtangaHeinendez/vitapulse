import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../domain/metric_sample.dart';
import '../domain/metric_type.dart';
import 'sync_providers.dart';

part 'detail_providers.g.dart';

enum ChartRange { day, week, month }

/// A single x/y point; [x2] carries the diastolic series for blood pressure.
class ChartPoint {
  const ChartPoint(this.x, this.y, [this.y2]);

  /// Day charts: hour of day (0–24). Week/month charts: day index.
  final double x;
  final double y;
  final double? y2;
}

class DetailData {
  const DetailData({
    required this.points,
    required this.min,
    required this.avg,
    required this.max,
    required this.history,
    required this.labels,
  });

  final List<ChartPoint> points;
  final double? min;
  final double? avg;
  final double? max;

  /// Recent raw samples, newest first (BP pre-paired as "sys/dia" strings).
  final List<HistoryEntry> history;

  /// x-index → axis label (week/month); empty for day charts.
  final Map<int, String> labels;
}

class HistoryEntry {
  const HistoryEntry(this.when, this.display, this.source);

  final DateTime when;
  final String display;
  final String source;
}

bool isCumulative(String key) => const {
      'steps',
      'water_intake',
      'calories_burned',
      'sleep_session',
    }.contains(key);

@riverpod
Future<DetailData> metricDetail(
    Ref ref, String metricKey, ChartRange range) async {
  // Refresh when new data lands.
  ref.watch(syncControllerProvider);
  ref.watch(dashboardDataProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    return const DetailData(
        points: [], min: null, avg: null, max: null, history: [], labels: {});
  }
  final repo = ref.watch(metricsRepositoryProvider);
  final isBp = metricKey == 'blood_pressure';
  final primary =
      isBp ? MetricType.bpSystolic : MetricType.fromDbName(metricKey);

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  if (range == ChartRange.day) {
    final samples =
        await repo.history(user.id, primary, from: startOfToday, to: now);
    List<MetricSample> dia = const [];
    if (isBp) {
      dia = await repo.history(user.id, MetricType.bpDiastolic,
          from: startOfToday, to: now);
    }

    List<ChartPoint> points;
    if (isCumulative(metricKey)) {
      // Hourly bars.
      final buckets = List<double>.filled(24, 0);
      for (final s in samples) {
        buckets[s.recordedAt.toLocal().hour] += s.value;
      }
      points = [
        for (var h = 0; h < 24; h++)
          if (buckets[h] > 0) ChartPoint(h.toDouble(), buckets[h]),
      ];
    } else {
      points = [
        for (final s in samples)
          ChartPoint(
            s.recordedAt.toLocal().hour +
                s.recordedAt.toLocal().minute / 60.0,
            s.value,
            isBp ? _closest(dia, s.recordedAt)?.value : null,
          ),
      ];
    }
    return DetailData(
      points: points,
      min: _min(samples),
      avg: _avg(samples),
      max: _max(samples),
      history: await _history(repo, user.id, metricKey, primary,
          from: startOfToday, to: now),
      labels: const {},
    );
  }

  // Week / month: one point per day from daily_summaries.
  final days = range == ChartRange.week ? 7 : 30;
  final rows = await repo.dailySummaries(user.id, days: days);
  final field = switch (metricKey) {
    'steps' => 'total_steps',
    'heart_rate' => 'avg_heart_rate',
    'sleep_session' => 'sleep_minutes',
    'blood_pressure' => 'bp_systolic',
    'spo2' => 'avg_spo2',
    'water_intake' => 'water_ml',
    'calories_burned' => 'calories',
    'weight' => 'weight_kg',
    _ => throw ArgumentError('unknown metric $metricKey'),
  };

  final firstDay = DateTime(now.year, now.month, now.day - (days - 1));
  final points = <ChartPoint>[];
  final labels = <int, String>{};
  final values = <double>[];
  for (final row in rows) {
    final day = DateTime.parse(row['day'] as String);
    final idx = day.difference(firstDay).inDays;
    if (idx < 0) continue;
    final v = (row[field] as num?)?.toDouble();
    final v2 = metricKey == 'blood_pressure'
        ? (row['bp_diastolic'] as num?)?.toDouble()
        : null;
    if (v == null) continue;
    values.add(v);
    points.add(ChartPoint(idx.toDouble(), v, v2));
  }
  for (var i = 0; i < days; i++) {
    final day = firstDay.add(Duration(days: i));
    if (range == ChartRange.week) {
      labels[i] = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];
    } else if (i % 7 == 0 || i == days - 1) {
      labels[i] = '${day.day}/${day.month}';
    }
  }

  return DetailData(
    points: points,
    min: values.isEmpty ? null : values.reduce((a, b) => a < b ? a : b),
    avg: values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length,
    max: values.isEmpty ? null : values.reduce((a, b) => a > b ? a : b),
    history: await _history(repo, user.id, metricKey, primary,
        from: firstDay, to: now),
    labels: labels,
  );
}

MetricSample? _closest(List<MetricSample> xs, DateTime at) {
  MetricSample? best;
  var bestDelta = const Duration(minutes: 30);
  for (final s in xs) {
    final d = (s.recordedAt.difference(at)).abs();
    if (d <= bestDelta) {
      bestDelta = d;
      best = s;
    }
  }
  return best;
}

double? _min(List<MetricSample> xs) => xs.isEmpty
    ? null
    : xs.map((s) => s.value).reduce((a, b) => a < b ? a : b);
double? _max(List<MetricSample> xs) => xs.isEmpty
    ? null
    : xs.map((s) => s.value).reduce((a, b) => a > b ? a : b);
double? _avg(List<MetricSample> xs) => xs.isEmpty
    ? null
    : xs.map((s) => s.value).reduce((a, b) => a + b) / xs.length;

String _fmtNum(double v) => v == v.roundToDouble()
    ? v.toInt().toString()
    : v.toStringAsFixed(1);

Future<List<HistoryEntry>> _history(
  dynamic repo,
  String userId,
  String metricKey,
  MetricType primary, {
  required DateTime from,
  required DateTime to,
}) async {
  final samples = (await repo.history(userId, primary, from: from, to: to))
      as List<MetricSample>;
  if (metricKey == 'blood_pressure') {
    final dia = (await repo.history(userId, MetricType.bpDiastolic,
        from: from, to: to)) as List<MetricSample>;
    final entries = [
      for (final s in samples.reversed.take(20))
        HistoryEntry(
          s.recordedAt,
          '${s.value.round()}/${_closest(dia, s.recordedAt)?.value.round() ?? '–'} mmHg',
          s.source,
        ),
    ];
    return entries;
  }
  return [
    for (final s in samples.reversed.take(20))
      HistoryEntry(
          s.recordedAt, '${_fmtNum(s.value)} ${primary.unit}', s.source),
  ];
}
