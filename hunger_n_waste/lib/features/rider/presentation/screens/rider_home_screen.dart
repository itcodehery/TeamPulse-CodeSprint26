import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/repositories/rider_repository.dart';
import '../../../auth/domain/models/rider_profile.dart';

final riderProfileStreamProvider = StreamProvider.autoDispose<RiderProfile?>((
  ref,
) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value(null);
  return ref.watch(riderRepositoryProvider).watchProfile(user.id);
});

final riderActiveJobsStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return Stream.value([]);
      return ref.watch(riderRepositoryProvider).watchActiveJobs(user.id);
    });

class RiderHomeScreen extends ConsumerWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(riderProfileStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Error: Profile not found'));
          }
          return _RiderDashboardContent(profile: profile);
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _RiderDashboardContent extends ConsumerWidget {
  final RiderProfile profile;

  const _RiderDashboardContent({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAvailable = profile.isAvailable;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Availability Card
          Card(
            elevation: 4,
            color: isAvailable ? Colors.green[50] : Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    isAvailable
                        ? Icons.check_circle
                        : Icons.pause_circle_filled,
                    size: 60,
                    color: isAvailable ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAvailable ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.green[800] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Accepting Jobs'),
                    value: isAvailable,
                    onChanged: (val) {
                      ref
                          .read(riderRepositoryProvider)
                          .updateAvailability(profile.id, val);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. Job Status (Placeholder for now)
          // 2. Job Status
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final jobsAsync = ref.watch(riderActiveJobsStreamProvider);

                return jobsAsync.when(
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return const Card(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bike,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text('No active jobs'),
                              Text('Wait for a donation request...'),
                            ],
                          ),
                        ),
                      );
                    }

                    final job = jobs.first; // Show the top job
                    return Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.delivery_dining,
                              size: 60,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'NEW DELIVERY REQUEST!',
                              style: Theme.of(context).textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Status: ${job['status'].toString().toUpperCase()}',
                            ),
                            const SizedBox(height: 8),
                            Text('Food Type: ${job['food_type']}'),
                            Text('Quantity: ${job['quantity']} servings'),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () {
                                // TODO: Handle Status Update (Pickup / Deliver)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Delivery flow to be implemented',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.navigation),
                              label: const Text('Start Delivery'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
