import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitapulse/core/services/prefs_service.dart';
import 'package:vitapulse/features/onboarding/presentation/onboarding_screen.dart';
import 'package:vitapulse/main.dart';

Future<Widget> _appWithPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const VitaPulseApp(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('intro navigates to onboarding on first run', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(await _appWithPrefs());

    expect(find.text('VitaPulse'), findsOneWidget);

    // Let the intro timer fire and the fade transition complete.
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('onboarding pages advance and Get started completes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(await _appWithPrefs());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Next'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Welcome to VitaPulse'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_complete'), isTrue);
  });

  testWidgets('intro skips onboarding when already completed', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    await tester.pumpWidget(await _appWithPrefs());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Welcome to VitaPulse'), findsOneWidget);
  });
}
