import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitapulse/features/auth/presentation/check_email_screen.dart';
import 'package:vitapulse/features/dashboard/presentation/home_screen.dart';
import 'package:vitapulse/features/profile/domain/profile.dart';
import 'package:vitapulse/features/profile/presentation/profile_setup_screen.dart';

import 'fakes.dart';
import 'onboarding_flow_test.dart' show appWithFakes;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpToSignIn(WidgetTester tester,
      {FakeAuthRepository? auth, FakeProfileRepository? profiles}) async {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    await tester.pumpWidget(await appWithFakes(auth: auth, profiles: profiles));
    await tester.pump(); // let the async router redirect resolve
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  testWidgets('sign in with new user lands on profile setup', (tester) async {
    final auth = FakeAuthRepository();
    await pumpToSignIn(tester, auth: auth);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'me@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
  });

  testWidgets('sign in with existing profile lands on home', (tester) async {
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository()
      ..profiles['user-1'] = const Profile(id: 'user-1', fullName: 'Atanga');
    await pumpToSignIn(tester, auth: auth, profiles: profiles);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'me@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('wrong password shows an error and stays on sign-in',
      (tester) async {
    await pumpToSignIn(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'me@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'wrong-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Invalid login credentials'), findsOneWidget);
  });

  testWidgets(
      'sign up without instant session goes to the check-email screen',
      (tester) async {
    final auth = FakeAuthRepository(confirmEmailOnSignUp: false);
    await pumpToSignIn(tester, auth: auth);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'new@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret1234');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'), 'secret1234');
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(CheckEmailScreen), findsOneWidget);
    expect(find.textContaining('new@example.com'), findsOneWidget);
    expect(auth.signUps, ['new@example.com']);
  });

  testWidgets('profile setup saves and continues to home', (tester) async {
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository();
    await pumpToSignIn(tester, auth: auth, profiles: profiles);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'me@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(ProfileSetupScreen), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full name'), 'Atanga');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Height'), '178');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Weight'), '74.5');
    await tester.tap(find.text('All set'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(profiles.profiles['user-1']?.fullName, 'Atanga');
    expect(profiles.weights, [74.5]);
  });
}
