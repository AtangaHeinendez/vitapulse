import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile.dart';

abstract class ProfileRepository {
  Future<Profile?> fetch(String userId);
  Future<void> upsert(Profile profile);

  /// Weight lives in `health_metrics`, not `profiles`.
  Future<void> logWeight({required String userId, required double weightKg});
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Profile?> fetch(String userId) async {
    final data =
        await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return data == null ? null : Profile.fromJson(data);
  }

  @override
  Future<void> upsert(Profile profile) =>
      _client.from('profiles').upsert(profile.toJson());

  @override
  Future<void> logWeight({required String userId, required double weightKg}) =>
      _client.from('health_metrics').upsert(
        {
          'user_id': userId,
          'metric_type': 'weight',
          'value': weightKg,
          'unit': 'kg',
          'recorded_at': DateTime.now().toUtc().toIso8601String(),
          'source': 'manual',
        },
        onConflict: 'user_id,metric_type,recorded_at,source',
      );
}
