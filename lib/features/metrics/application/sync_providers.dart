import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/prefs_service.dart';
import '../../../core/services/supabase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/health_source.dart';
import '../data/metrics_repository.dart';
import '../domain/metric_sample.dart';
import '../domain/metric_type.dart';

part 'sync_providers.g.dart';

/// Set with --dart-define=MOCK_HEALTH=true to feed fake data on emulators.
const kMockHealth = bool.fromEnvironment('MOCK_HEALTH');

@Riverpod(keepAlive: true)
HealthSource healthSource(Ref ref) {
  if (kIsWeb) return NullHealthSource();
  if (kMockHealth) return MockHealthSource();
  return HealthConnectSource(ref.watch(sharedPrefsProvider));
}

@Riverpod(keepAlive: true)
MetricsRepository metricsRepository(Ref ref) =>
    SupabaseMetricsRepository(ref.watch(supabaseClientProvider));

class SyncState {
  const SyncState({
    this.available = false,
    this.permissionsGranted = false,
    this.lastSyncedAt,
    this.lastSampleCount = 0,
  });

  final bool available;
  final bool permissionsGranted;
  final DateTime? lastSyncedAt;
  final int lastSampleCount;

  bool get connected => available && permissionsGranted;

  SyncState copyWith({
    bool? available,
    bool? permissionsGranted,
    DateTime? lastSyncedAt,
    int? lastSampleCount,
  }) =>
      SyncState(
        available: available ?? this.available,
        permissionsGranted: permissionsGranted ?? this.permissionsGranted,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        lastSampleCount: lastSampleCount ?? this.lastSampleCount,
      );
}

/// Latest stored value of each metric (refreshes after every sync).
@riverpod
Future<List<MetricSample>> latestMetrics(Ref ref) async {
  // Refetch after every sync (and on connect/disconnect).
  ref.watch(syncControllerProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const [];
  return ref.watch(metricsRepositoryProvider).latestOfEachType(user.id);
}

/// Orchestrates: Health Connect -> health_metrics -> daily_summaries.
/// No-ops on web, where the dashboard only reads what the phone synced.
@Riverpod(keepAlive: true)
class SyncController extends _$SyncController {
  @override
  Future<SyncState> build() async {
    if (kIsWeb) return const SyncState();
    final source = ref.watch(healthSourceProvider);
    final available = await source.isAvailable();
    final granted = available && await source.hasPermissions();
    return SyncState(available: available, permissionsGranted: granted);
  }

  /// Shows the system permission sheet (after the app's rationale UI),
  /// then runs a first sync when granted.
  Future<bool> connect() async {
    final source = ref.read(healthSourceProvider);
    final granted = await source.requestPermissions();
    state = AsyncData(
      (state.value ?? const SyncState(available: true))
          .copyWith(permissionsGranted: granted, available: true),
    );
    if (granted) await syncNow();
    return granted;
  }

  /// Fetches the last 30 days, upserts to Supabase and recomputes summaries.
  Future<void> syncNow() async {
    if (kIsWeb) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    final current = state.value ?? const SyncState();
    if (user == null || !current.connected) return;

    final source = ref.read(healthSourceProvider);
    final repo = ref.read(metricsRepositoryProvider);

    final samples = await source.fetchSamples();

    // Phone-sensor fallback when Health Connect has no steps for today.
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final hasStepsToday = samples.any((s) =>
        s.type == MetricType.steps && !s.recordedAt.isBefore(startOfToday));
    if (!hasStepsToday) {
      final fallback = await source.fallbackTodaySteps();
      if (fallback != null && fallback > 0) {
        samples.add(MetricSample(
          type: MetricType.steps,
          value: fallback.toDouble(),
          // Fixed timestamp so re-syncs update the same row instead of
          // stacking new ones (unique key includes recorded_at + source).
          recordedAt: startOfToday,
          source: 'pedometer',
        ));
      }
    }

    if (samples.isNotEmpty) {
      await repo.upsertSamples(user.id, samples);
      final days = samples.map((s) {
        final local = s.recordedAt.toLocal();
        return DateTime(local.year, local.month, local.day);
      }).toSet();
      await repo.recomputeDailySummaries(
          days, DateTime.now().timeZoneOffset.inMinutes);
    }

    state = AsyncData(current.copyWith(
      lastSyncedAt: DateTime.now(),
      lastSampleCount: samples.length,
    ));
  }
}
