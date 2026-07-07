import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitapulse/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:vitapulse/features/dashboard/presentation/widgets/steps_ring_card.dart';
import 'package:vitapulse/features/metrics/domain/metric_sample.dart';
import 'package:vitapulse/features/metrics/domain/metric_type.dart';
import 'package:vitapulse/features/profile/domain/profile.dart';

import 'fakes.dart';
import 'onboarding_flow_test.dart' show appWithFakes;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSignedIn(WidgetTester tester,
      {required FakeMetricsRepository metrics}) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository()
      ..profiles['user-1'] = const Profile(
          id: 'user-1', fullName: 'Atanga', stepGoal: 8000, waterGoalMl: 2000);
    await tester
        .pumpWidget(await appWithFakes(auth: auth, profiles: profiles, metrics: metrics));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'me@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('dashboard renders steps ring and metric cards with data',
      (tester) async {
    final now = DateTime.now();
    final metrics = FakeMetricsRepository()
      ..samples.addAll([
        MetricSample(
            type: MetricType.steps,
            value: 4200,
            recordedAt: now.subtract(const Duration(hours: 1))),
        MetricSample(
            type: MetricType.heartRate,
            value: 72,
            recordedAt: now.subtract(const Duration(hours: 2))),
        MetricSample(
            type: MetricType.heartRate,
            value: 78,
            recordedAt: now.subtract(const Duration(hours: 1))),
        MetricSample(
            type: MetricType.bpSystolic, value: 118, recordedAt: now),
        MetricSample(
            type: MetricType.bpDiastolic, value: 76, recordedAt: now),
        MetricSample(type: MetricType.spo2, value: 97, recordedAt: now),
        MetricSample(
            type: MetricType.waterIntake, value: 500, recordedAt: now),
        MetricSample(
            type: MetricType.caloriesBurned, value: 1450, recordedAt: now),
        MetricSample(
            type: MetricType.weight,
            value: 74.5,
            recordedAt: now,
            source: 'manual'),
      ]);

    await pumpSignedIn(tester, metrics: metrics);

    expect(find.byType(StepsRingCard), findsOneWidget);
    expect(find.text('Steps today'), findsOneWidget);
    expect(find.byType(MetricCard), findsNWidgets(7));
    expect(find.textContaining('118/76', findRichText: true), findsOneWidget);
    expect(find.textContaining('74.5', findRichText: true), findsOneWidget);
    expect(
        find.textContaining('500', findRichText: true), findsOneWidget);
  });

  testWidgets('water quick-add logs 250 ml through the entry service',
      (tester) async {
    final metrics = FakeMetricsRepository();
    await pumpSignedIn(tester, metrics: metrics);

    await tester.ensureVisible(find.text('250'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('250'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(
      metrics.samples
          .where((s) =>
              s.type == MetricType.waterIntake &&
              s.value == 250 &&
              s.source == 'manual')
          .length,
      1,
    );
    expect(metrics.recomputedDays, isNotEmpty);
  });
}
