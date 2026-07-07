import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_providers.dart';
import '../../metrics/application/sync_providers.dart';
import '../../metrics/domain/metric_sample.dart';
import '../../metrics/domain/metric_type.dart';
import '../../profile/application/profile_providers.dart';

part 'dashboard_providers.g.dart';

class DashboardData {
  const DashboardData({
    this.todaySteps = 0,
    this.todayWaterMl = 0,
    this.todayCalories = 0,
    this.lastNightSleepMinutes,
    this.latest = const {},
    this.heartRateSpark = const [],
    this.weightTrend = const [],
    this.stepGoal = 8000,
    this.waterGoalMl = 2000,
  });

  final int todaySteps;
  final int todayWaterMl;
  final double todayCalories;
  final int? lastNightSleepMinutes;

  /// Latest sample of each metric type.
  final Map<MetricType, MetricSample> latest;

  /// Today's heart-rate values in time order (for the mini sparkline).
  final List<double> heartRateSpark;

  /// Recent daily weights, oldest → newest (for the trend arrow).
  final List<double> weightTrend;

  final int stepGoal;
  final int waterGoalMl;
}

@riverpod
Future<DashboardData> dashboardData(Ref ref) async {
  // Refresh whenever a sync completes.
  ref.watch(syncControllerProvider);
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return const DashboardData();

  final repo = ref.watch(metricsRepositoryProvider);
  final profile = await ref.watch(currentProfileProvider.future);

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);

  final results = await Future.wait([
    repo.latestOfEachType(user.id),
    repo.history(user.id, MetricType.steps, from: startOfToday, to: now),
    repo.history(user.id, MetricType.waterIntake, from: startOfToday, to: now),
    repo.history(user.id, MetricType.caloriesBurned,
        from: startOfToday, to: now),
    repo.history(user.id, MetricType.heartRate, from: startOfToday, to: now),
    repo.history(user.id, MetricType.sleepSession,
        from: startOfToday, to: now),
    repo.history(user.id, MetricType.weight,
        from: now.subtract(const Duration(days: 30)), to: now),
  ]);

  final latestList = results[0];
  double sum(List<MetricSample> xs) =>
      xs.fold(0.0, (acc, s) => acc + s.value);

  final sleepToday = results[5];

  return DashboardData(
    todaySteps: sum(results[1]).round(),
    todayWaterMl: sum(results[2]).round(),
    todayCalories: sum(results[3]),
    lastNightSleepMinutes:
        sleepToday.isEmpty ? null : sum(sleepToday).round(),
    latest: {for (final s in latestList) s.type: s},
    heartRateSpark: [for (final s in results[4]) s.value],
    weightTrend: [for (final s in results[6]) s.value],
    stepGoal: profile?.stepGoal ?? 8000,
    waterGoalMl: profile?.waterGoalMl ?? 2000,
  );
}
