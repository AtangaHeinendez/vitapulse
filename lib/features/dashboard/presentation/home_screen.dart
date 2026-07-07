import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_providers.dart';
import '../../metrics/application/sync_providers.dart';
import '../../metrics/domain/metric_sample.dart';
import '../../profile/application/profile_providers.dart';

/// Phase 3 home: health-data connection + sync pipeline proof.
/// The full dashboard (rings, cards, charts) lands in Phase 4.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentProfileProvider).value;
    final sync = ref.watch(syncControllerProvider);
    final firstName = profile?.fullName?.split(' ').first ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(syncControllerProvider.notifier).syncNow(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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
                      IconButton(
                        tooltip: 'Sign out',
                        onPressed: () =>
                            ref.read(authRepositoryProvider).signOut(),
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: sync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _StatusCard(
                      icon: Icons.error_outline_rounded,
                      color: theme.colorScheme.error,
                      title: 'Health data unavailable',
                      body: '$e',
                    ),
                    data: (s) => s.connected
                        ? _SyncedHeader(state: s)
                        : _ConnectCard(available: s.available),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                sliver: _LatestMetricsList(),
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.all(24),
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
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Connect your health data',
                    style: theme.textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            available
                ? 'VitaPulse reads your steps, heart rate, sleep, SpO₂, blood '
                    'pressure, weight and calories from Health Connect — where '
                    'your Galaxy Watch data lands via Samsung Health. Your data '
                    'stays in your own private database and is never shared.'
                : 'Health Connect isn’t available on this device. Install it '
                    'from the Play Store, then in Samsung Health enable '
                    'Settings → Health Connect data sync.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: .7),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: available
                ? () async {
                    final ok = await ref
                        .read(syncControllerProvider.notifier)
                        .connect();
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Permission not granted — you can retry anytime.'),
                      ));
                    }
                  }
                : null,
            icon: const Icon(Icons.link_rounded),
            label: const Text('Connect Health Connect'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: .05);
  }
}

class _SyncedHeader extends StatelessWidget {
  const _SyncedHeader({required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = state.lastSyncedAt;
    return Row(
      children: [
        Icon(Icons.sync_rounded, size: 18, color: AppColors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            last == null
                ? 'Connected — pull down to sync'
                : 'Synced ${DateFormat.Hm().format(last)} · '
                    '${state.lastSampleCount} samples · pull to refresh',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: .6),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadow(context),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestMetricsList extends ConsumerWidget {
  const _LatestMetricsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final latest = ref.watch(latestMetricsProvider);
    return latest.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load metrics: $e'),
        ),
      ),
      data: (samples) {
        if (samples.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No data yet — connect and sync to see your metrics.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .5),
                  ),
                ),
              ),
            ),
          );
        }
        return SliverList.separated(
          itemCount: samples.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _MetricTile(sample: samples[i], index: i),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.sample, required this.index});

  final MetricSample sample;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = sample.type;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(t.icon, color: t.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.label, style: theme.textTheme.titleSmall),
                Text(
                  DateFormat.MMMd().add_Hm().format(sample.recordedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .5),
                  ),
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              text: sample.value == sample.value.roundToDouble()
                  ? sample.value.toInt().toString()
                  : sample.value.toStringAsFixed(1),
              style: theme.textTheme.titleLarge?.copyWith(color: t.accent),
              children: [
                TextSpan(
                  text: ' ${t.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: .5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (reduceMotion) return tile;
    return tile
        .animate(delay: (60 * index).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: .08, curve: Curves.easeOutCubic);
  }
}
