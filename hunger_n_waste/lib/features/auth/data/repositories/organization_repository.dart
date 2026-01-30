import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/organization_profile.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(Supabase.instance.client);
});

class OrganizationRepository {
  final SupabaseClient _client;

  OrganizationRepository(this._client);

  Future<void> createProfile(OrganizationProfile profile) async {
    await _client.from('organization_profiles').insert(profile.toJson());
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
