import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitapulse/features/auth/data/auth_repository.dart';
import 'package:vitapulse/features/metrics/data/metrics_repository.dart';
import 'package:vitapulse/features/metrics/domain/metric_sample.dart';
import 'package:vitapulse/features/metrics/domain/metric_type.dart';
import 'package:vitapulse/features/profile/data/profile_repository.dart';
import 'package:vitapulse/features/profile/domain/profile.dart';

User _fakeUser(String email) => User(
      id: 'user-1',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );

Session _fakeSession(String email) => Session(
      accessToken: 'token',
      tokenType: 'bearer',
      user: _fakeUser(email),
    );

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.confirmEmailOnSignUp = true});

  /// When false, [signUp] behaves like Supabase with email confirmation on:
  /// user created but no session issued.
  final bool confirmEmailOnSignUp;

  final _controller = StreamController<AuthState>.broadcast();
  Session? _session;

  final signUps = <String>[];
  final resets = <String>[];

  @override
  Session? get currentSession => _session;

  @override
  User? get currentUser => _session?.user;

  @override
  Stream<AuthState> get onAuthStateChange => _controller.stream;

  @override
  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    if (password == 'wrong-password') {
      throw const AuthException('Invalid login credentials');
    }
    _session = _fakeSession(email);
    _controller.add(AuthState(AuthChangeEvent.signedIn, _session));
    return AuthResponse(session: _session, user: _session!.user);
  }

  @override
  Future<AuthResponse> signUp(
      {required String email, required String password}) async {
    signUps.add(email);
    if (!confirmEmailOnSignUp) {
      return AuthResponse(session: null, user: _fakeUser(email));
    }
    _session = _fakeSession(email);
    _controller.add(AuthState(AuthChangeEvent.signedIn, _session));
    return AuthResponse(session: _session, user: _session!.user);
  }

  @override
  Future<void> signOut() async {
    _session = null;
    _controller.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Future<void> sendPasswordReset(String email) async => resets.add(email);

  @override
  Future<void> resendConfirmation(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}
}

class FakeMetricsRepository implements MetricsRepository {
  final samples = <MetricSample>[];
  final recomputedDays = <DateTime>{};

  @override
  Future<void> upsertSamples(String userId, List<MetricSample> s) async {
    samples.addAll(s);
  }

  @override
  Future<void> recomputeDailySummaries(
      Set<DateTime> days, int utcOffsetMinutes) async {
    recomputedDays.addAll(days);
  }

  @override
  Future<List<MetricSample>> latestOfEachType(String userId) async {
    final seen = <MetricType>{};
    final sorted = [...samples]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return [
      for (final s in sorted)
        if (seen.add(s.type)) s,
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> dailySummaries(String userId,
          {int days = 30}) async =>
      const [];

  @override
  Future<List<MetricSample>> history(String userId, MetricType type,
          {required DateTime from, required DateTime to}) async =>
      [
        for (final s in samples)
          if (s.type == type &&
              !s.recordedAt.isBefore(from) &&
              !s.recordedAt.isAfter(to))
            s,
      ];
}

class FakeProfileRepository implements ProfileRepository {
  final profiles = <String, Profile>{};
  final weights = <double>[];

  @override
  Future<Profile?> fetch(String userId) async => profiles[userId];

  @override
  Future<void> upsert(Profile profile) async => profiles[profile.id] = profile;

  @override
  Future<void> logWeight(
      {required String userId, required double weightKg}) async {
    weights.add(weightKg);
  }
}
