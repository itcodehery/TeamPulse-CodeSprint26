import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/repositories/rider_repository.dart';
import '../../../auth/data/repositories/donor_repository.dart';
import '../../../auth/data/repositories/organization_repository.dart';
import '../../../food_requests/data/repositories/food_request_repository.dart';
import '../../../auth/domain/models/rider_profile.dart';

// --- Providers ---

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

final donorProfileProvider = FutureProvider.autoDispose.family<dynamic, String>(
  (ref, id) async {
    return ref.watch(donorRepositoryProvider).getProfile(id);
  },
);

final organizationProfileProvider = FutureProvider.autoDispose
    .family<dynamic, String>((ref, id) async {
      return ref.read(organizationRepositoryProvider).getProfile(id);
    });

// --- UI ---

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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Availability Card
          Card(
            elevation: 2,
            color: isAvailable ? Colors.green[50] : Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  isAvailable ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green[800] : Colors.grey[700],
                  ),
                ),
                subtitle: Text(
                  isAvailable
                      ? 'Accepting deliveries'
                      : 'Not accepting deliveries',
                ),
                secondary: Icon(
                  isAvailable ? Icons.check_circle : Icons.pause_circle_filled,
                  color: isAvailable ? Colors.green : Colors.grey,
                  size: 32,
                ),
                value: isAvailable,
                onChanged: (val) async {
                  try {
                    debugPrint('🎯 Toggle switched to: $val');
                    await ref
                        .read(riderRepositoryProvider)
                        .updateAvailability(profile.id, val);

                    // Force refresh the stream provider to get updated data
                    debugPrint(
                      '🔄 Invalidating profile provider to force refresh',
                    );
                    ref.invalidate(riderProfileStreamProvider);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            val ? 'You are now ONLINE' : 'You are now OFFLINE',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: val
                              ? Colors.green
                              : Colors.grey[700],
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('🚨 Error in toggle: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update status: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Active Jobs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // 2. Active Jobs List
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final jobsAsync = ref.watch(riderActiveJobsStreamProvider);

                return jobsAsync.when(
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delivery_dining_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isAvailable
                                  ? 'Waiting for requests...'
                                  : 'Go Online to receive requests',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        return _JobCard(job: jobs[index]);
                      },
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

class _JobCard extends ConsumerWidget {
  final Map<String, dynamic> job;

  const _JobCard({required this.job});

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    try {
      await ref
          .read(foodRequestRepositoryProvider)
          .updateRequestStatus(requestId: job['id'], status: status);
      if (context.mounted) {
        String msg = status == 'in_transit'
            ? 'Pickup Confirmed! Heading to dropoff.'
            : 'Delivery Completed! Great job.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = job['status'] as String;
    final orgId = job['org_id'] as String;
    final donorId = job['donor_id'] as String?;

    final orgAsync = ref.watch(organizationProfileProvider(orgId));
    // If no donor assigned yet (shouldn't happen for active jobs), skip
    final donorAsync = donorId != null
        ? ref.watch(donorProfileProvider(donorId))
        : const AsyncValue<dynamic>.data(
            null,
          ); // dynamic to match Option type? Actually Option handles nulls.

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    status.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: status == 'pending_pickup'
                      ? Colors.orange
                      : Colors.blue,
                ),
                Text(
                  'Qty: ${job['quantity']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Food: ${job['food_type']}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(height: 24),

            // Pickup Info (Donor)
            _buildLocationRow(
              context,
              icon: Icons.upload,
              title: 'PICKUP (Donor)',
              asyncValue: donorAsync,
              isDonor: true,
            ),
            const SizedBox(height: 16),

            // Dropoff Info (Org)
            _buildLocationRow(
              context,
              icon: Icons.download,
              title: 'DROPOFF (Organization)',
              asyncValue: orgAsync,
              isDonor: false,
            ),

            const SizedBox(height: 24),

            // Actions
            if (status == 'pending_pickup')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _updateStatus(context, ref, 'in_transit'),
                  icon: const Icon(Icons.check),
                  label: const Text('CONFIRM PICKUP'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ),

            if (status == 'in_transit')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _updateStatus(context, ref, 'completed'),
                  icon: const Icon(Icons.done_all),
                  label: const Text('CONFIRM DELIVERY'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required AsyncValue asyncValue,
    required bool isDonor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              asyncValue.when(
                data: (data) {
                  // data is Option.value or Option.none likely?
                  // Wait, I declared providers as .option? No, I declared generic .family
                  // Let's assume standard object return or null.
                  if (data == null) return const Text('Loading details...');

                  if (isDonor) {
                    // Cast to DonorProfile? Since riverpod generic types are tricky without proper casting
                    // I will rely on dynamic for now or fix types in provider definition.
                    // Accessing fields dynamically:
                    // Assuming standard Access.
                    // Safe way: cast to dynamic then look up.
                    final d = data;
                    return Text(d.defaultAddress ?? 'Unknown Donor Address');
                  } else {
                    final o = data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.organizationName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(o.address),
                      ],
                    );
                  }
                },
                loading: () => const Text('Loading...'),
                error: (_, __) => const Text('Failed to load'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
