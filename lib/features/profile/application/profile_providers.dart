import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

part 'profile_providers.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    SupabaseProfileRepository(ref.watch(supabaseClientProvider));

/// The signed-in user's profile row (null when signed out or not created yet).
@Riverpod(keepAlive: true)
class CurrentProfile extends _$CurrentProfile {
  @override
  Future<Profile?> build() async {
    // Re-fetch whenever the auth state changes (sign in/out, new user).
    ref.watch(authStateChangesProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return null;
    return ref.watch(profileRepositoryProvider).fetch(user.id);
  }

  Future<void> save(Profile profile, {double? weightKg}) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.upsert(profile);
    if (weightKg != null) {
      await repo.logWeight(userId: profile.id, weightKg: weightKg);
    }
    state = AsyncData(profile);
  }
}
