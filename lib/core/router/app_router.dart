import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/check_email_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/metrics/presentation/metric_detail_screen.dart';
import '../../features/onboarding/presentation/intro_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/application/profile_providers.dart';
import '../../features/profile/domain/profile.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/reminders/presentation/reminders_screen.dart';
import '../services/prefs_service.dart';

abstract final class Routes {
  static const intro = '/intro';
  static const onboarding = '/onboarding';
  static const signIn = '/auth/sign-in';
  static const signUp = '/auth/sign-up';
  static const checkEmail = '/auth/check-email';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const profileSetup = '/profile-setup';
  static const home = '/home';
  static const settings = '/settings';
  static const reminders = '/reminders';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authStateChangesProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: Routes.intro,
    refreshListenable: refresh,
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      // The intro plays once and then navigates itself; leave it alone.
      if (loc == Routes.intro) return null;

      if (!ref.read(prefsServiceProvider).onboardingComplete) {
        return loc == Routes.onboarding ? null : Routes.onboarding;
      }
      if (loc == Routes.onboarding) return Routes.home; // already onboarded

      final signedIn =
          ref.read(authRepositoryProvider).currentSession != null;
      final inAuthFlow = loc.startsWith('/auth');

      if (!signedIn) return inAuthFlow ? null : Routes.signIn;

      // Password recovery must stay reachable while signed in via the
      // recovery deep link.
      if (loc == Routes.resetPassword) return null;

      // On flaky mobile data the profile fetch can stall behind a hanging
      // auth-session refresh; never strand the user on the intro screen.
      // When the profile can't be determined in time, proceed to the
      // requested destination — the dashboard has its own loading states.
      final Profile? profile;
      try {
        profile = await ref
            .read(currentProfileProvider.future)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        return inAuthFlow || loc == Routes.intro ? Routes.home : null;
      }
      final needsSetup = profile == null || !profile.isComplete;
      if (needsSetup) {
        return loc == Routes.profileSetup ? null : Routes.profileSetup;
      }
      if (inAuthFlow || loc == Routes.profileSetup) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.intro,
        pageBuilder: (context, state) => _fadePage(state, const IntroScreen()),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) =>
            _fadePage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: Routes.signIn,
        pageBuilder: (context, state) => _fadePage(state, const SignInScreen()),
      ),
      GoRoute(
        path: Routes.signUp,
        pageBuilder: (context, state) => _fadePage(state, const SignUpScreen()),
      ),
      GoRoute(
        path: Routes.checkEmail,
        pageBuilder: (context, state) => _fadePage(
          state,
          CheckEmailScreen(email: state.uri.queryParameters['email'] ?? ''),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        pageBuilder: (context, state) =>
            _fadePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: Routes.resetPassword,
        pageBuilder: (context, state) =>
            _fadePage(state, const ResetPasswordScreen()),
      ),
      GoRoute(
        path: Routes.profileSetup,
        pageBuilder: (context, state) =>
            _fadePage(state, const ProfileSetupScreen()),
      ),
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => _fadePage(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/metric/:key',
        builder: (context, state) =>
            MetricDetailScreen(metricKey: state.pathParameters['key']!),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.reminders,
        builder: (context, state) => const RemindersScreen(),
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
