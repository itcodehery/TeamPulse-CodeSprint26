import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/food_request_repository.dart';
import '../../domain/models/food_request.dart';
import '../../../auth/domain/models/organization_profile.dart';

final activeRequestsProvider = StreamProvider.autoDispose<List<FoodRequest>>((
  ref,
) {
  final repository = ref.watch(foodRequestRepositoryProvider);

  return repository.watchActiveRequests().asyncMap((requests) async {
    final orgIds = requests.map((r) => r.orgId).toSet().toList();
    if (orgIds.isEmpty) return requests;

    final profilesResponse = await Supabase.instance.client
        .from('organization_profiles')
        .select()
        .filter('id', 'in', orgIds);

    final profileMap = {
      for (var json in profilesResponse as List)
        json['id']: OrganizationProfile.fromJson(json),
    };

    return requests.map((req) {
      final profile = profileMap[req.orgId];
      return req.copyWith(organization: profile);
    }).toList();
  });
});
