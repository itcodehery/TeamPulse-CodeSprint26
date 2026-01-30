import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../food_requests/data/repositories/food_request_repository.dart';
import '../../../food_requests/domain/models/food_request.dart';

final donorNotificationsProvider =
    StreamProvider.autoDispose<List<FoodRequest>>((ref) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return Stream.value([]);

      return ref
          .watch(foodRequestRepositoryProvider)
          .watchDonorContributions(user.id);
    });
