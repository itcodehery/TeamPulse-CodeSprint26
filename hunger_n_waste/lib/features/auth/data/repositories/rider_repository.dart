import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/rider_profile.dart';

final riderRepositoryProvider = Provider<RiderRepository>((ref) {
  return RiderRepository(Supabase.instance.client);
});

class RiderRepository {
  final SupabaseClient _client;

  RiderRepository(this._client);

  Future<void> createProfile({
    required RiderProfile riderProfile,
    required String email,
    required String name,
  }) async {
    // 1. Create Profile
    await _client.from('profiles').insert({
      'id': riderProfile.id,
      'email': email,
      'name': name,
      'user_type': 'rider',
    });

    // 2. Create Rider Profile
    await _client.from('rider_profiles').insert(riderProfile.toJson());
  }

  Future<RiderProfile?> getProfile(String id) async {
    final response = await _client
        .from('rider_profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return RiderProfile.fromJson(response);
  }

  Future<void> updateAvailability(String id, bool isAvailable) async {
    try {
      debugPrint(
        '🔄 Updating rider availability: id=$id, isAvailable=$isAvailable',
      );

      final response = await _client
          .from('rider_profiles')
          .update({'is_available': isAvailable})
          .eq('id', id)
          .select();

      debugPrint('✅ Availability update successful: $response');
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating availability: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Stream<RiderProfile?> watchProfile(String id) {
    debugPrint('📡 Setting up stream for rider: $id');
    return _client
        .from('rider_profiles')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((event) {
          debugPrint('📨 Stream received update: $event');
          if (event.isEmpty) return null;
          final profile = RiderProfile.fromJson(event.first);
          debugPrint('🔄 Parsed profile - isAvailable: ${profile.isAvailable}');
          return profile;
        });
  }

  Stream<List<Map<String, dynamic>>> watchActiveJobs(String riderId) {
    return _client
        .from('food_requests')
        .stream(primaryKey: ['id'])
        .eq('rider_id', riderId)
        .order('created_at', ascending: false)
        .map((event) {
          return event.where((job) => job['status'] != 'completed').toList();
        });
  }
}
