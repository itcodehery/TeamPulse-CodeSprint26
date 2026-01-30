import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/models/organization_profile.dart';

final currentOrganizationProvider =
    FutureProvider.autoDispose<OrganizationProfile?>((ref) async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      try {
        final response = await Supabase.instance.client
            .from('organization_profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (response == null) return null;
        return OrganizationProfile.fromJson(response);
      } catch (e) {
        return null;
      }
    });
