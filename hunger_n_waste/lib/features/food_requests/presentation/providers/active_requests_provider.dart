import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/food_request_repository.dart';
import '../../domain/models/food_request.dart';

final activeRequestsProvider = FutureProvider.autoDispose<List<FoodRequest>>((
  ref,
) async {
  final repository = ref.watch(foodRequestRepositoryProvider);
  return repository.getActiveRequests();
});
