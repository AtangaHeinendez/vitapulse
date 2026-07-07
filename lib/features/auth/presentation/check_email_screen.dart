import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_router.dart';
import '../application/auth_providers.dart';
import 'widgets/auth_shell.dart';

/// Shown after sign-up when email confirmation is required.
class CheckEmailScreen extends ConsumerStatefulWidget {
  const CheckEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends ConsumerState<CheckEmailScreen> {
  bool _busy = false;

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).resendConfirmation(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirmation email sent again.')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Check your inbox',
      subtitle:
          'We sent a confirmation link to\n${widget.email}\n\nTap it, then come back and sign in.',
      icon: Icons.mark_email_read_rounded,
      children: [
        FilledButton(
          onPressed: () => context.go(Routes.signIn),
          child: const Text('I’ve confirmed — sign in'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy ? null : _resend,
          child: const Text('Resend email'),
        ),
      ],
    );
  }
}
