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
          'latitude': latitude,
          'longitude': longitude,
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

  Future<List<FoodRequest>> getDonorContributions(String donorId) async {
    final response = await _client
        .from('food_requests')
        .select('*, organization_profiles(*)')
        .eq('donor_id', donorId)
        .neq(
          'status',
          'open',
        ) // Assuming contributions are fulfilled/closed/pending
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FoodRequest.fromJson(json))
        .toList();
  }

  Future<void> fulfillRequest({
    required String requestId,
    required String donorId,
  }) async {
    // 1. Find and Assign Rider (Simulation)
    final availableRiders = await _client
        .from('rider_profiles')
        .select()
        .eq('is_available', true)
        .limit(1);

    String? assignedRiderId;
    if (availableRiders.isNotEmpty) {
      assignedRiderId = availableRiders.first['id'] as String;
    }

    // 2. Update Status and Assign Rider
    await _client
        .from('food_requests')
        .update({
          'status': 'pending_pickup',
          'donor_id': donorId,
          'rider_id': assignedRiderId,
        })
        .eq('id', requestId);

    // Optional: Set rider to unavailable
    if (assignedRiderId != null) {
      // await _client.from('rider_profiles').update({
      //   'is_available': false,
      // }).eq('id', assignedRiderId);
    }
  }
}
