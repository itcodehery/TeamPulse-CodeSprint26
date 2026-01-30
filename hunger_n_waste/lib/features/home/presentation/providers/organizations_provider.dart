import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/organization_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final allOrganizationsProvider =
    FutureProvider.autoDispose<List<OrganizationProfile>>((ref) async {
      final client = Supabase.instance.client;

      final response = await client
          .from('organization_profiles')
          .select()
          .order('organization_name', ascending: true);

      return (response as List)
          .map((json) => OrganizationProfile.fromJson(json))
          .toList();
    });
