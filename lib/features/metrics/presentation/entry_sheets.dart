import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../water/application/water_service.dart';

enum ManualEntryKind { water, weight, bloodPressure }

Future<void> showManualEntrySheet(BuildContext context, ManualEntryKind kind) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: switch (kind) {
        ManualEntryKind.water => const _WaterSheet(),
        ManualEntryKind.weight => const _WeightSheet(),
        ManualEntryKind.bloodPressure => const _BpSheet(),
      },
    ),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.accent,
    required this.icon,
    required this.children,
  });

  final String title;
  final Color accent;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title, style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _WaterSheet extends ConsumerStatefulWidget {
  const _WaterSheet();

  @override
  ConsumerState<_WaterSheet> createState() => _WaterSheetState();
}

class _WaterSheetState extends ConsumerState<_WaterSheet> {
  int _ml = 250;
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    await ref.read(manualEntryServiceProvider).logWater(_ml);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Log water',
      accent: AppColors.water,
      icon: Icons.water_drop_rounded,
      children: [
        Wrap(
          spacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final amount in const [150, 250, 330, 500, 750])
              ChoiceChip(
                label: Text('$amount ml'),
                selected: _ml == amount,
                selectedColor: AppColors.water.withValues(alpha: .2),
                onSelected: (_) => setState(() => _ml = amount),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.water,
              foregroundColor: Colors.white),
          onPressed: _busy ? null : _save,
          child: Text('Add $_ml ml'),
        ),
      ],
    );
  }
}

class _WeightSheet extends ConsumerStatefulWidget {
  const _WeightSheet();

  @override
  ConsumerState<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends ConsumerState<_WeightSheet> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (v == null || v < 20 || v > 400) return;
    setState(() => _busy = true);
    await ref.read(manualEntryServiceProvider).logWeight(v);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Log weight',
      accent: AppColors.weight,
      icon: Icons.monitor_weight_rounded,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight',
            suffixText: 'kg',
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.weight,
              foregroundColor: Colors.white),
          onPressed: _busy ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _BpSheet extends ConsumerStatefulWidget {
  const _BpSheet();

  @override
  ConsumerState<_BpSheet> createState() => _BpSheetState();
}

class _BpSheetState extends ConsumerState<_BpSheet> {
  final _sys = TextEditingController();
  final _dia = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _sys.dispose();
    _dia.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final sys = int.tryParse(_sys.text);
    final dia = int.tryParse(_dia.text);
    if (sys == null || dia == null || sys < 50 || sys > 260 || dia < 30 ||
        dia > 200) {
      return;
    }
    setState(() => _busy = true);
    await ref.read(manualEntryServiceProvider).logBloodPressure(sys, dia);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Log blood pressure',
      accent: AppColors.bloodPressure,
      icon: Icons.bloodtype_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _sys,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Systolic',
                  suffixText: 'mmHg',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _dia,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Diastolic',
                  suffixText: 'mmHg',
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.bloodPressure,
              foregroundColor: Colors.white),
          onPressed: _busy ? null : _save,
          child: const Text('Save reading'),
        ),
      ],
    );
  }
}
