import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../metrics/application/sync_providers.dart';
import '../../metrics/domain/metric_type.dart';
import '../../profile/application/profile_providers.dart';
import '../../water/application/water_service.dart';
import '../application/dashboard_providers.dart';
import 'widgets/metric_card.dart';
import 'widgets/steps_ring_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentProfileProvider).value;
    final sync = ref.watch(syncControllerProvider);
    final dash = ref.watch(dashboardDataProvider);
    final firstName = profile?.fullName?.split(' ').first ?? 'there';
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final content = RefreshIndicator(
          onRefresh: () async {
            await ref.read(syncControllerProvider.notifier).syncNow();
            ref.invalidate(dashboardDataProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hi, $firstName 👋',
                                style: theme.textTheme.headlineSmall),
                            Text(
                              DateFormat.MMMMEEEEd().format(DateTime.now()),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: .55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isWide)
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () => context.push(Routes.settings),
                          icon: const Icon(Icons.settings_rounded),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                sliver: SliverToBoxAdapter(child: _SyncStatusLine(sync: sync)),
              ),
              if (!kIsWeb &&
                  sync.value != null &&
                  !sync.value!.connected &&
                  !kMockHealth)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  sliver: SliverToBoxAdapter(
                    child: _ConnectCard(
                        available: sync.value?.available ?? false),
                  ),
                ),
              dash.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 40,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: .35)),
                        const SizedBox(height: 12),
                        Text(
                          e is TimeoutException
                              ? 'The connection is slow right now — your data '
                                  'is safe. Pull down to try again.'
                              : 'Could not load your dashboard. Pull down to '
                                  'try again.\n($e)',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: .6),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (d) => _DashboardBody(data: d),
              ),
            ],
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  _SideNav(),
                  const VerticalDivider(width: 1, thickness: .5),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: content,
                      ),
                    ),
                  ),
                ],
              )
            : content,
      ),
    );
  }
}

/// Sidebar navigation shown on wide (web/tablet) layouts.
class _SideNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: 0,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
          ),
          child:
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_rounded),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_rounded),
          label: Text('Settings'),
        ),
      ],
      onDestinationSelected: (i) {
        if (i == 1) context.push(Routes.settings);
      },
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.data});

  final DashboardData data;

  String _fmtSleep(int? minutes) {
    if (minutes == null || minutes == 0) return '—';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final latest = data.latest;

    final hr = latest[MetricType.heartRate];
    final sys = latest[MetricType.bpSystolic];
    final dia = latest[MetricType.bpDiastolic];
    final spo2 = latest[MetricType.spo2];
    final weight = latest[MetricType.weight];

    String weightSub = 'Weight';
    if (data.weightTrend.length >= 2) {
      final delta = data.weightTrend.last - data.weightTrend.first;
      final arrow = delta.abs() < .1 ? '→' : (delta > 0 ? '↑' : '↓');
      weightSub = 'Weight $arrow ${delta.abs().toStringAsFixed(1)} kg / 30d';
    }

    final cards = <Widget>[
      MetricCard(
        accent: AppColors.heartRate,
        icon: MetricType.heartRate.icon,
        title: 'Heart rate',
        subtitle: 'Heart rate',
        value: hr == null ? '—' : hr.value.round().toString(),
        unit: 'bpm',
        heroTag: 'metric-heart_rate',
        sparkline: data.heartRateSpark,
        onTap: () => context.push('/metric/heart_rate'),
      ),
      MetricCard(
        accent: AppColors.sleep,
        icon: MetricType.sleepSession.icon,
        title: 'Sleep',
        subtitle: 'Last night',
        value: _fmtSleep(data.lastNightSleepMinutes),
        heroTag: 'metric-sleep_session',
        onTap: () => context.push('/metric/sleep_session'),
      ),
      MetricCard(
        accent: AppColors.bloodPressure,
        icon: MetricType.bpSystolic.icon,
        title: 'Blood pressure',
        subtitle: 'Blood pressure',
        value: sys == null || dia == null
            ? '—'
            : '${sys.value.round()}/${dia.value.round()}',
        unit: 'mmHg',
        heroTag: 'metric-blood_pressure',
        onTap: () => context.push('/metric/blood_pressure'),
      ),
      MetricCard(
        accent: AppColors.spo2,
        icon: MetricType.spo2.icon,
        title: 'SpO₂',
        subtitle: 'Blood oxygen',
        value: spo2 == null ? '—' : spo2.value.round().toString(),
        unit: '%',
        heroTag: 'metric-spo2',
        onTap: () => context.push('/metric/spo2'),
      ),
      MetricCard(
        accent: AppColors.water,
        icon: MetricType.waterIntake.icon,
        title: 'Water',
        subtitle: 'of ${data.waterGoalMl} ml goal',
        value: data.todayWaterMl.toString(),
        unit: 'ml',
        heroTag: 'metric-water_intake',
        trailing: _QuickAddWater(),
        onTap: () => context.push('/metric/water_intake'),
      ),
      MetricCard(
        accent: AppColors.calories,
        icon: MetricType.caloriesBurned.icon,
        title: 'Calories',
        subtitle: 'Burned today',
        value: data.todayCalories == 0
            ? '—'
            : data.todayCalories.round().toString(),
        unit: 'kcal',
        heroTag: 'metric-calories_burned',
        onTap: () => context.push('/metric/calories_burned'),
      ),
      MetricCard(
        accent: AppColors.weight,
        icon: MetricType.weight.icon,
        title: 'Weight',
        subtitle: weightSub,
        value: weight == null ? '—' : weight.value.toStringAsFixed(1),
        unit: 'kg',
        heroTag: 'metric-weight',
        onTap: () => context.push('/metric/weight'),
      ),
    ];

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          reduceMotion
              ? StepsRingCard(
                  steps: data.todaySteps,
                  goal: data.stepGoal,
                  onTap: () => context.push('/metric/steps'),
                )
              : StepsRingCard(
                  steps: data.todaySteps,
                  goal: data.stepGoal,
                  onTap: () => context.push('/metric/steps'),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: .06),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth >= 980
                    ? 4
                    : (constraints.maxWidth >= 660 ? 3 : 2),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.08,
              ),
              itemCount: cards.length,
              itemBuilder: (context, i) {
                final card = cards[i];
                if (reduceMotion) return card;
                return card
                    .animate(delay: (80 + 70 * i).ms)
                    .fadeIn(duration: 380.ms)
                    .slideY(begin: .1, curve: Curves.easeOutCubic);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _QuickAddWater extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 34,
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: AppColors.water.withValues(alpha: .18),
          foregroundColor: AppColors.water,
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        onPressed: () async {
          await ref.read(manualEntryServiceProvider).logWater(250);
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                  const SnackBar(content: Text('+250 ml logged 💧')));
          }
        },
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('250'),
      ),
    );
  }
}

class _SyncStatusLine extends StatelessWidget {
  const _SyncStatusLine({required this.sync});

  final AsyncValue<SyncState> sync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = sync.value;
    final text = kIsWeb
        ? 'Live from your database — your phone keeps it synced'
        : switch (s) {
            null => 'Checking health data…',
            SyncState(connected: false) => 'Health data not connected',
            SyncState(lastSyncedAt: null) => 'Connected — pull down to sync',
            SyncState(:final lastSyncedAt?, :final lastSampleCount) =>
              'Synced ${DateFormat.Hm().format(lastSyncedAt)} · '
                  '$lastSampleCount samples · pull to refresh',
          };
    return Row(
      children: [
        Icon(Icons.sync_rounded,
            size: 16,
            color: kIsWeb || (s?.connected ?? false)
                ? AppColors.teal
                : theme.colorScheme.onSurface.withValues(alpha: .4)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: .55),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectCard extends ConsumerWidget {
  const _ConnectCard({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Connect your health data',
                    style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            available
                ? 'VitaPulse reads your watch data from Health Connect. It '
                    'stays in your private database and is never shared.'
                : 'Health Connect isn’t available here. Install it from the '
                    'Play Store and enable Samsung Health → Settings → '
                    'Health Connect data sync.',
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: .65),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: available
                ? () => ref.read(syncControllerProvider.notifier).connect()
                : null,
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('Connect Health Connect'),
          ),
        ],
      ),
    );
  }
}
