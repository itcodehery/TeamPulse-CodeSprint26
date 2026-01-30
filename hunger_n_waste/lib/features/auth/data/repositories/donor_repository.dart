import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/donor_profile.dart';

final donorRepositoryProvider = Provider<DonorRepository>((ref) {
  return DonorRepository(Supabase.instance.client);
});

class DonorRepository {
  final SupabaseClient _client;

  DonorRepository(this._client);

  Future<void> createProfile({
    required DonorProfile donorProfile,
    required String email,
    required String name,
  }) async {
    // 1. Create Profile
    await _client.from('profiles').insert({
      'id': donorProfile.id,
      'email': email,
      'name': name,
      'user_type': 'donor',
    });

    // 2. Create Donor Profile
    await _client.from('donor_profiles').insert(donorProfile.toJson());
  }

  Future<DonorProfile?> getProfile(String id) async {
    final response = await _client
        .from('donor_profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return DonorProfile.fromJson(response);
  }
}
