import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../metrics/application/sync_providers.dart';
import '../../metrics/domain/metric_sample.dart';
import '../../metrics/domain/metric_type.dart';

part 'water_service.g.dart';

/// Writes manual entries (water, weight, blood pressure) to Supabase,
/// mirrors water to Health Connect, and refreshes the affected days.
@Riverpod(keepAlive: true)
ManualEntryService manualEntryService(Ref ref) => ManualEntryService(ref);

class ManualEntryService {
  ManualEntryService(this._ref);

  final Ref _ref;

  Future<void> logWater(int ml, {DateTime? at}) async {
    final when = at ?? DateTime.now();
    await _log([
      MetricSample(
        type: MetricType.waterIntake,
        value: ml.toDouble(),
        recordedAt: when,
        source: 'manual',
      ),
    ]);
    // Best-effort mirror into Health Connect hydration.
    await _ref.read(healthSourceProvider).writeWater(ml.toDouble(), when);
  }

  Future<void> logWeight(double kg, {DateTime? at}) => _log([
        MetricSample(
          type: MetricType.weight,
          value: kg,
          recordedAt: at ?? DateTime.now(),
          source: 'manual',
        ),
      ]);

  Future<void> logBloodPressure(int systolic, int diastolic,
      {DateTime? at}) {
    final when = at ?? DateTime.now();
    return _log([
      MetricSample(
        type: MetricType.bpSystolic,
        value: systolic.toDouble(),
        recordedAt: when,
        source: 'manual',
      ),
      MetricSample(
        type: MetricType.bpDiastolic,
        value: diastolic.toDouble(),
        recordedAt: when,
        source: 'manual',
      ),
    ]);
  }

  Future<void> _log(List<MetricSample> samples) async {
    final user = _ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    final repo = _ref.read(metricsRepositoryProvider);
    await repo.upsertSamples(user.id, samples);
    final days = samples.map((s) {
      final l = s.recordedAt.toLocal();
      return DateTime(l.year, l.month, l.day);
    }).toSet();
    await repo.recomputeDailySummaries(
        days, DateTime.now().timeZoneOffset.inMinutes);
    _ref.invalidate(dashboardDataProvider);
    _ref.invalidate(latestMetricsProvider);
  }
}
