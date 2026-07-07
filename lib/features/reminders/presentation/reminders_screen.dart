import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../application/reminders_service.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(remindersProvider);
    final notifier = ref.read(remindersProvider.notifier);

    Widget card({required Widget child}) => Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: softShadow(context),
          ),
          child: child,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(Icons.water_drop_rounded,
                      color: AppColors.water),
                  title: const Text('Drink water'),
                  subtitle: const Text('Regular nudges through the day'),
                  value: settings.waterEnabled,
                  onChanged: (v) =>
                      notifier.update(settings.copyWith(waterEnabled: v)),
                ),
                if (settings.waterEnabled) ...[
                  const SizedBox(height: 6),
                  Text('Every', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final h in const [2, 3, 4])
                        ChoiceChip(
                          label: Text('$h hours'),
                          selected: settings.waterIntervalHours == h,
                          onSelected: (_) => notifier.update(
                              settings.copyWith(waterIntervalHours: h)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _HourDropdown(
                          label: 'From',
                          value: settings.waterStartHour,
                          onChanged: (v) => notifier
                              .update(settings.copyWith(waterStartHour: v)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HourDropdown(
                          label: 'Until',
                          value: settings.waterEndHour,
                          onChanged: (v) => notifier
                              .update(settings.copyWith(waterEndHour: v)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          card(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(Icons.bloodtype_rounded,
                      color: AppColors.bloodPressure),
                  title: const Text('Measure blood pressure'),
                  subtitle: const Text('Once a day at a fixed time'),
                  value: settings.bpEnabled,
                  onChanged: (v) =>
                      notifier.update(settings.copyWith(bpEnabled: v)),
                ),
                if (settings.bpEnabled)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Time'),
                    trailing: Text(
                      TimeOfDay(
                              hour: settings.bpHour,
                              minute: settings.bpMinute)
                          .format(context),
                      style: theme.textTheme.titleMedium,
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                            hour: settings.bpHour,
                            minute: settings.bpMinute),
                      );
                      if (picked != null) {
                        notifier.update(settings.copyWith(
                            bpHour: picked.hour, bpMinute: picked.minute));
                      }
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Reminders are delivered as local notifications. Android may ask '
            'for notification permission the first time you enable one.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: .5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HourDropdown extends StatelessWidget {
  const _HourDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (var h = 5; h <= 23; h++)
          DropdownMenuItem(value: h, child: Text('$h:00')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
