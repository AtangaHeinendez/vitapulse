import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitapulse/core/services/prefs_service.dart';
import 'package:vitapulse/features/auth/application/auth_providers.dart';
import 'package:vitapulse/features/auth/presentation/sign_in_screen.dart';
import 'package:vitapulse/features/metrics/application/sync_providers.dart';
import 'package:vitapulse/features/metrics/data/health_source.dart';
import 'package:vitapulse/features/onboarding/presentation/onboarding_screen.dart';
import 'package:vitapulse/features/profile/application/profile_providers.dart';
import 'package:vitapulse/main.dart';

import 'fakes.dart';

Future<Widget> appWithFakes({
  FakeAuthRepository? auth,
  FakeProfileRepository? profiles,
  FakeMetricsRepository? metrics,
}) async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
      profileRepositoryProvider
          .overrideWithValue(profiles ?? FakeProfileRepository()),
      metricsRepositoryProvider
          .overrideWithValue(metrics ?? FakeMetricsRepository()),
      healthSourceProvider.overrideWithValue(MockHealthSource()),
    ],
    child: const VitaPulseApp(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('intro navigates to onboarding on first run', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(await appWithFakes());
    await tester.pump(); // let the async router redirect resolve

    expect(find.text('VitaPulse'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('onboarding completes into the sign-in screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(await appWithFakes());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(SignInScreen), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_complete'), isTrue);
  });

  testWidgets('intro skips onboarding when already completed', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    await tester.pumpWidget(await appWithFakes());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
