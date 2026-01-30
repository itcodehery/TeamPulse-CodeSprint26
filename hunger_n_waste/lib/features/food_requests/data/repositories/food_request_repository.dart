import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/food_request.dart';
import '../../../auth/domain/models/rider_profile.dart';

final foodRequestRepositoryProvider = Provider<FoodRequestRepository>((ref) {
  return FoodRequestRepository(Supabase.instance.client);
});

class FoodRequestRepository {
  final SupabaseClient _client;
  static const _uuid = Uuid();

  FoodRequestRepository(this._client);

  Future<FoodRequest> createRequest({
    required String orgId,
    required String foodType,
    required int quantity,
    required double latitude,
    required double longitude,
  }) async {
    // Generate unique UUID for the request
    final requestId = _uuid.v4();

    print('🔵 [CREATE REQUEST] Generated UUID: $requestId');
    print('🔵 [CREATE REQUEST] Inserting with orgId: $orgId');

    final response = await _client
        .from('food_requests')
        .insert({
          'id': requestId,
          'org_id': orgId,
          'food_type': foodType,
          'quantity': quantity,
          'status': 'open',
          'latitude': latitude,
          'longitude': longitude,
        })
        .select()
        .single();

    print('🟢 [CREATE REQUEST] Response: $response');
    print(
      '🟢 [CREATE REQUEST] Response ID type: ${response['id'].runtimeType}',
    );
    print('🟢 [CREATE REQUEST] Response status: ${response['status']}');

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
    print('🔵 [WATCH REQUESTS] Watching for orgId: $orgId');
    return _client
        .from('food_requests')
        .stream(primaryKey: ['id'])
        .eq('org_id', orgId)
        .order('created_at', ascending: false)
        .map((data) {
          print('🟢 [WATCH REQUESTS] Received ${data.length} requests');
          for (var i = 0; i < data.length; i++) {
            print('🟢 [WATCH REQUESTS] Request $i: ${data[i]}');
            print(
              '🟢 [WATCH REQUESTS] Request $i ID: ${data[i]['id']} (type: ${data[i]['id'].runtimeType})',
            );
            print(
              '🟢 [WATCH REQUESTS] Request $i status: ${data[i]['status']}',
            );
          }
          return data.map((json) {
            return FoodRequest.fromJson(json);
          }).toList();
        });
  }

  // Stream for available orders (pending pickup) for riders
  Stream<List<FoodRequest>> watchAvailableOrders() {
    print(
      '🔵 [WATCH AVAILABLE ORDERS] Setting up stream for pending_pickup orders',
    );
    return _client
        .from('food_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending_pickup')
        .order('created_at', ascending: false)
        .map((data) {
          print('🟢 [WATCH AVAILABLE ORDERS] Received ${data.length} orders');
          return data.map((json) => FoodRequest.fromJson(json)).toList();
        });
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

  // Stream for donor contributions (for notifications)
  Stream<List<FoodRequest>> watchDonorContributions(String donorId) {
    print(
      '🔵 [WATCH DONOR CONTRIBUTIONS] Setting up stream for donor: $donorId',
    );
    return _client
        .from('food_requests')
        .stream(primaryKey: ['id'])
        .eq('donor_id', donorId)
        .order('created_at', ascending: false)
        .map((data) {
          print(
            '🟢 [WATCH DONOR CONTRIBUTIONS] Received ${data.length} contributions',
          );
          return data.map((json) => FoodRequest.fromJson(json)).toList();
        });
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
    required String deliveryType, // 'self' or 'service'
    LatLng? pickupLocation, // Optional, only needed for delivery service
  }) async {
    String? assignedRiderId;
    String status;

    // Only assign rider for delivery service
    if (deliveryType == 'service') {
      if (pickupLocation == null) {
        throw Exception('Pickup location required for delivery service');
      }

      // 2. Fetch all Available Riders
      final availableRidersData = await _client
          .from('rider_profiles')
          .select()
          .eq('is_available', true);

      final riders = (availableRidersData as List)
          .map((json) => RiderProfile.fromJson(json))
          .toList();

      if (riders.isNotEmpty) {
        // 3. Find Request Location (Use Pickup Location)
        final requestLoc = pickupLocation;
        const distance = Distance();

        // 4. Separate riders with and without location data
        final ridersWithLocation = riders
            .where(
              (r) => r.currentLatitude != null && r.currentLongitude != null,
            )
            .toList();

        if (ridersWithLocation.isNotEmpty) {
          // 5. Sort by Distance (only those with location)
          ridersWithLocation.sort((a, b) {
            final locA = LatLng(a.currentLatitude!, a.currentLongitude!);
            final locB = LatLng(b.currentLatitude!, b.currentLongitude!);

            final distA = distance.as(LengthUnit.Meter, requestLoc, locA);
            final distB = distance.as(LengthUnit.Meter, requestLoc, locB);

            return distA.compareTo(distB);
          });

          // 6. Pick the closest one
          assignedRiderId = ridersWithLocation.first.id;
        } else {
          // 7. Fallback: No riders have location data, assign first available
          assignedRiderId = riders.first.id;
        }
      }

      status = 'pending_pickup';
    } else {
      // Self-delivery: no rider needed
      status = 'self_delivery';
    }

    // Update Request Status & Assign Rider (if applicable)
    await _client
        .from('food_requests')
        .update({
          'status': status,
          'donor_id': donorId,
          if (assignedRiderId != null) 'rider_id': assignedRiderId,
        })
        .eq('id', requestId);

    // Optional: Set assigned rider to unavailable
    if (assignedRiderId != null) {
      // await _client.from('rider_profiles').update({
      //   'is_available': false,
      // }).eq('id', assignedRiderId);
    }
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await _client
        .from('food_requests')
        .update({'status': status})
        .eq('id', requestId);
  }
}
