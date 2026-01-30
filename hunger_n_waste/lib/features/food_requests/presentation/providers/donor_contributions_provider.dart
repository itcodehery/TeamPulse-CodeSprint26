import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/food_request_repository.dart';
import '../../domain/models/food_request.dart';

final donorContributionsProvider =
    FutureProvider.autoDispose<List<FoodRequest>>((ref) async {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      final repository = ref.watch(foodRequestRepositoryProvider);
      return repository.getDonorContributions(user.id);
    });
