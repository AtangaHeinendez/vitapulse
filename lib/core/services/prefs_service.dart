import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injected in [main] after [SharedPreferences.getInstance] resolves.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

final prefsServiceProvider = Provider<PrefsService>(
  (ref) => PrefsService(ref.watch(sharedPrefsProvider)),
);

class PrefsService {
  PrefsService(this._prefs);

  final SharedPreferences _prefs;

  static const _kOnboardingComplete = 'onboarding_complete';

  bool get onboardingComplete => _prefs.getBool(_kOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete() => _prefs.setBool(_kOnboardingComplete, true);
}
