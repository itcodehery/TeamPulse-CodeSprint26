import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/organization_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final allOrganizationsProvider =
    StreamProvider.autoDispose<List<OrganizationProfile>>((ref) {
      return Supabase.instance.client
          .from('organization_profiles')
          .stream(primaryKey: ['id'])
          .order('organization_name', ascending: true)
          .map(
            (data) =>
                data.map((json) => OrganizationProfile.fromJson(json)).toList(),
          );
    });
