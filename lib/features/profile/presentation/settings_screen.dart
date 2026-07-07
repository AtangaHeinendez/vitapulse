import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/profile_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String suffix,
    required int current,
    required int min,
    required int max,
    required int step,
    required Future<void> Function(int) onSave,
  }) async {
    var value = current;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () =>
                        setState(() => value = (value - step).clamp(min, max)),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('$value $suffix',
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  IconButton.filledTonal(
                    onPressed: () =>
                        setState(() => value = (value + step).clamp(min, max)),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) await onSave(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentProfileProvider).value;
    final email = ref.watch(authRepositoryProvider).currentUser?.email;

    Widget section(List<Widget> children) => Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: softShadow(context),
          ),
          child: Column(children: children),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          section([
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 24),
              ),
              title: Text(profile?.fullName ?? '—',
                  style: theme.textTheme.titleMedium),
              subtitle: Text(email ?? ''),
            ),
          ]),
          const SizedBox(height: 14),
          section([
            ListTile(
              leading:
                  Icon(Icons.directions_walk_rounded, color: AppColors.steps),
              title: const Text('Daily step goal'),
              trailing: Text('${profile?.stepGoal ?? 8000}',
                  style: theme.textTheme.titleMedium),
              onTap: profile == null
                  ? null
                  : () => _editGoal(
                        context,
                        ref,
                        title: 'Daily step goal',
                        suffix: 'steps',
                        current: profile.stepGoal,
                        min: 2000,
                        max: 30000,
                        step: 500,
                        onSave: (v) async {
                          await ref
                              .read(currentProfileProvider.notifier)
                              .save(profile.copyWith(stepGoal: v));
                          ref.invalidate(dashboardDataProvider);
                        },
                      ),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: Icon(Icons.water_drop_rounded, color: AppColors.water),
              title: const Text('Daily water goal'),
              trailing: Text('${profile?.waterGoalMl ?? 2000} ml',
                  style: theme.textTheme.titleMedium),
              onTap: profile == null
                  ? null
                  : () => _editGoal(
                        context,
                        ref,
                        title: 'Daily water goal',
                        suffix: 'ml',
                        current: profile.waterGoalMl,
                        min: 500,
                        max: 5000,
                        step: 250,
                        onSave: (v) async {
                          await ref
                              .read(currentProfileProvider.notifier)
                              .save(profile.copyWith(waterGoalMl: v));
                          ref.invalidate(dashboardDataProvider);
                        },
                      ),
            ),
            // Local notification reminders are a phone-only feature.
            if (!kIsWeb) ...[
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(Icons.notifications_active_rounded,
                    color: AppColors.calories),
                title: const Text('Reminders'),
                subtitle: const Text('Water and blood pressure'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(Routes.reminders),
              ),
            ],
          ]),
          const SizedBox(height: 14),
          section([
            ListTile(
              leading: Icon(Icons.logout_rounded,
                  color: theme.colorScheme.error),
              title: Text('Sign out',
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go(Routes.signIn);
              },
            ),
          ]),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'VitaPulse v0.1.0 · your data stays in your own database',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: .4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
