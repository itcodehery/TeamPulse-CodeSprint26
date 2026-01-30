import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/organization_profile.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(Supabase.instance.client);
});

class OrganizationRepository {
  final SupabaseClient _client;

  OrganizationRepository(this._client);

  Future<void> createProfile({
    required OrganizationProfile orgProfile,
    required String email,
  }) async {
    // 1. Create Profile
    await _client.from('profiles').insert({
      'id': orgProfile.id,
      'email': email,
      'name': orgProfile.organizationName,
      'user_type': 'organization',
    });

    // 2. Create Organization Profile
    await _client.from('organization_profiles').insert(orgProfile.toJson());
  }

  Future<OrganizationProfile?> getProfile(String id) async {
    try {
      final response = await _client
          .from('organization_profiles')
          .select()
          .eq('id', id)
          .single();
      return OrganizationProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
