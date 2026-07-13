import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/metric_sample.dart';
import '../domain/metric_type.dart';

/// Reads/writes `health_metrics` and `daily_summaries` in Supabase.
abstract class MetricsRepository {
  Future<void> upsertSamples(String userId, List<MetricSample> samples);
  Future<void> recomputeDailySummaries(Set<DateTime> days, int utcOffsetMinutes);
  Future<List<MetricSample>> latestOfEachType(String userId);
  Future<List<Map<String, dynamic>>> dailySummaries(String userId, {int days = 30});
  Future<List<MetricSample>> history(
    String userId,
    MetricType type, {
    required DateTime from,
    required DateTime to,
  });
}

class SupabaseMetricsRepository implements MetricsRepository {
  SupabaseMetricsRepository(this._client);

  final SupabaseClient _client;

  static const _batchSize = 500;

  /// Reads on the dashboard/detail critical path must not hang forever on
  /// stalled mobile-data connections.
  static const _readTimeout = Duration(seconds: 15);

  @override
  Future<void> upsertSamples(String userId, List<MetricSample> samples) async {
    for (var i = 0; i < samples.length; i += _batchSize) {
      final batch = samples
          .sublist(i, (i + _batchSize).clamp(0, samples.length))
          .map((s) => s.toRow(userId))
          .toList();
      await _client.from('health_metrics').upsert(
            batch,
            onConflict: 'user_id,metric_type,recorded_at,source',
            ignoreDuplicates: false,
          );
    }
  }

  @override
  Future<void> recomputeDailySummaries(
      Set<DateTime> days, int utcOffsetMinutes) async {
    if (days.isEmpty) return;
    final dayStrings = days
        .map((d) => d.toIso8601String().substring(0, 10))
        .toSet()
        .toList();
    await _client.rpc<void>('recompute_daily_summaries', params: {
      'p_days': dayStrings,
      'p_offset_minutes': utcOffsetMinutes,
    });
  }

  @override
  Future<List<MetricSample>> latestOfEachType(String userId) async {
    final rows = await _client
        .from('health_metrics')
        .select('metric_type, value, recorded_at, source')
        .eq('user_id', userId)
        .order('recorded_at', ascending: false)
        .limit(400)
        .timeout(_readTimeout);
    final seen = <String>{};
    final result = <MetricSample>[];
    for (final row in rows) {
      if (seen.add(row['metric_type'] as String)) {
        result.add(MetricSample.fromRow(row));
      }
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> dailySummaries(String userId,
      {int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    return _client
        .from('daily_summaries')
        .select()
        .eq('user_id', userId)
        .gte('day', since.toIso8601String().substring(0, 10))
        .order('day', ascending: true)
        .timeout(_readTimeout);
  }

  @override
  Future<List<MetricSample>> history(
    String userId,
    MetricType type, {
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _client
        .from('health_metrics')
        .select('metric_type, value, recorded_at, source')
        .eq('user_id', userId)
        .eq('metric_type', type.dbName)
        .gte('recorded_at', from.toUtc().toIso8601String())
        .lte('recorded_at', to.toUtc().toIso8601String())
        .order('recorded_at', ascending: true)
        .timeout(_readTimeout);
    return rows.map(MetricSample.fromRow).toList();
  }
}
