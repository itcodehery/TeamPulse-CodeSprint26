import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/food_request.dart';

final foodRequestRepositoryProvider = Provider<FoodRequestRepository>((ref) {
  return FoodRequestRepository(Supabase.instance.client);
});

class FoodRequestRepository {
  final SupabaseClient _client;

  FoodRequestRepository(this._client);

  Future<FoodRequest> createRequest({
    required String orgId,
    required String foodType,
    required int quantity,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _client
        .from('food_requests')
        .insert({
          'org_id': orgId,
          'food_type': foodType,
          'quantity': quantity,
          'status': 'open',
          'location':
              'POINT($longitude $latitude)', // PostGIS format if using geography, or separate lat/long columns. Plan mentioned geography.
        })
        .select()
        .single();

    return FoodRequest.fromJson(response);
  }

  Future<List<FoodRequest>> getRequestsByOrgId(String orgId) async {
    final response = await _client
        .from('food_requests')
        .select()
        .eq('org_id', orgId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FoodRequest.fromJson(json))
        .toList();
  }

  // Stream for real-time updates for an Org
  Stream<List<FoodRequest>> watchRequestsByOrgId(String orgId) {
    return _client
        .from('food_requests')
        .stream(primaryKey: ['id'])
        .eq('org_id', orgId)
        .order('created_at', ascending: false)
        .map((maps) => maps.map((map) => FoodRequest.fromJson(map)).toList());
  }

  Future<List<FoodRequest>> getActiveRequests() async {
    final response = await _client
        .from('food_requests')
        .select('*, organization_profiles(*)')
        .eq('status', 'open')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FoodRequest.fromJson(json))
        .toList();
  }
}
