import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/widgets/auth_shell.dart';
import '../application/profile_providers.dart';
import '../domain/profile.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  DateTime? _dob;
  String? _gender;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      final profile = Profile(
        id: user.id,
        fullName: _name.text.trim(),
        dateOfBirth: _dob,
        gender: _gender,
        heightCm: double.tryParse(_height.text.replaceAll(',', '.')),
      );
      final weightKg = double.tryParse(_weight.text.replaceAll(',', '.'));
      await ref
          .read(currentProfileProvider.notifier)
          .save(profile, weightKg: weightKg);
      if (mounted) context.go(Routes.home);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthShell(
      title: 'Tell us about you',
      subtitle: 'This helps us personalize goals and stats.',
      icon: Icons.emoji_people_rounded,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDob,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of birth',
                    prefixIcon: Icon(Icons.cake_rounded),
                  ),
                  child: Text(
                    _dob == null
                        ? 'Tap to select'
                        : DateFormat.yMMMMd().format(_dob!),
                    style: _dob == null
                        ? theme.textTheme.bodyLarge?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withValues(alpha: .5))
                        : theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final g in const ['Female', 'Male', 'Other'])
                      ChoiceChip(
                        label: Text(g),
                        selected: _gender == g,
                        onSelected: (_) => setState(() => _gender = g),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _height,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        suffixText: 'cm',
                        prefixIcon: Icon(Icons.height_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        return n == null || n < 50 || n > 260
                            ? '50–260'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        suffixText: 'kg',
                        prefixIcon: Icon(Icons.monitor_weight_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        return n == null || n < 20 || n > 400 ? '20–400' : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              BusyButton(label: 'All set', busy: _busy, onPressed: _submit),
            ],
          ),
        ),
      ],
    );
  }
}
