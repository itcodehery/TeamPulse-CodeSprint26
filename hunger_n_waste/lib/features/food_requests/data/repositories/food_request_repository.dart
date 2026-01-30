import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/food_request.dart';
import '../../auth/domain/models/rider_profile.dart';

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
    // 1. Get the Request details to know the Pickup Location
    final requestData = await _client
        .from('food_requests')
        .select('latitude, longitude')
        .eq('id', requestId)
        .single();

    final double requestLat = requestData['latitude'];
    final double requestLong = requestData['longitude'];

    // 2. Fetch all Available Riders
    final availableRidersData = await _client
        .from('rider_profiles')
        .select()
        .eq('is_available', true);

    final riders = (availableRidersData as List)
        .map((json) => RiderProfile.fromJson(json))
        .toList();

    String? assignedRiderId;

    if (riders.isNotEmpty) {
      // 3. Find Request Location
      final requestLoc = LatLng(requestLat, requestLong);
      const distance = Distance();

      // 4. Sort by Distance
      riders.sort((a, b) {
        if (a.currentLatitude == null || a.currentLongitude == null) return 1;
        if (b.currentLatitude == null || b.currentLongitude == null) return -1;

        final locA = LatLng(a.currentLatitude!, a.currentLongitude!);
        final locB = LatLng(b.currentLatitude!, b.currentLongitude!);

        final distA = distance.as(LengthUnit.Meter, requestLoc, locA);
        final distB = distance.as(LengthUnit.Meter, requestLoc, locB);

        return distA.compareTo(distB);
      });

      // 5. Pick the closest one
      // (Filtering out those without location if needed, but sort handles it)
      if (riders.first.currentLatitude != null) {
        assignedRiderId = riders.first.id;
      }
    }

    // 6. Update Request Status & Assign Rider
    await _client
        .from('food_requests')
        .update({
          'status': 'pending_pickup',
          'donor_id': donorId,
          'rider_id': assignedRiderId,
        })
        .eq('id', requestId);

    // Optional: Set assigned rider to unavailable
    if (assignedRiderId != null) {
      // await _client.from('rider_profiles').update({
      //   'is_available': false,
      // }).eq('id', assignedRiderId);
    }
  }
}
