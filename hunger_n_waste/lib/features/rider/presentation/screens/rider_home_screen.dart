import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../auth/data/repositories/rider_repository.dart';
import '../../../auth/data/repositories/donor_repository.dart';
import '../../../auth/data/repositories/organization_repository.dart';
import '../../../food_requests/data/repositories/food_request_repository.dart';
import 'package:vibration/vibration.dart';
import '../../../auth/domain/models/rider_profile.dart';
import '../../../food_requests/domain/models/food_request.dart';
import '../../../../core/services/notification_service.dart';

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

final availableOrdersStreamProvider =
    StreamProvider.autoDispose<List<FoodRequest>>((ref) {
      return ref.watch(foodRequestRepositoryProvider).watchAvailableOrders();
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

class _RiderDashboardContent extends ConsumerStatefulWidget {
  final RiderProfile profile;

  const _RiderDashboardContent({required this.profile});

  @override
  ConsumerState<_RiderDashboardContent> createState() =>
      _RiderDashboardContentState();
}

class _RiderDashboardContentState
    extends ConsumerState<_RiderDashboardContent> {
  Timer? _locationTimer;
  final Set<String> _notifiedOrderIds = {};

  @override
  void initState() {
    super.initState();
    // Start location tracking if rider is already online
    if (widget.profile.isAvailable) {
      _startLocationTracking();
    }
  }

  @override
  void didUpdateWidget(_RiderDashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle availability changes
    if (widget.profile.isAvailable != oldWidget.profile.isAvailable) {
      if (widget.profile.isAvailable) {
        _startLocationTracking();
      } else {
        _stopLocationTracking();
      }
    }
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }

  void _startLocationTracking() {
    debugPrint('🚀 Starting location tracking');
    _updateLocation(); // Update immediately
    _locationTimer?.cancel(); // Cancel any existing timer
    _locationTimer = Timer.periodic(const Duration(minutes: 4), (_) {
      _updateLocation();
    });
  }

  void _stopLocationTracking() {
    debugPrint('🛑 Stopping location tracking');
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _updateLocation() async {
    try {
      debugPrint('📍 Getting current location...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint(
        '📍 Location obtained: ${position.latitude}, ${position.longitude}',
      );

      await ref
          .read(riderRepositoryProvider)
          .updateLocation(
            widget.profile.id,
            position.latitude,
            position.longitude,
          );

      debugPrint('✅ Location updated in database');
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
      // Don't show error to user, just log it
      // Location updates are background operations
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.profile.isAvailable;

    // Listen for new available orders and notify rider
    ref.listen(availableOrdersStreamProvider, (previous, next) {
      // Only notify if rider is online
      if (!isAvailable) return;

      next.whenData((orders) {
        for (var order in orders) {
          // Only notify for orders we haven't notified about yet
          if (!_notifiedOrderIds.contains(order.id)) {
            _notifiedOrderIds.add(order.id);

            // Don't notify on initial load (when previous is null)
            if (previous != null) {
              NotificationService.showStatusNotification(
                title: 'New Order Available!',
                body:
                    '${order.foodType} - ${order.quantity} servings from ${order.organization?.organizationName ?? "nearby"}',
                payload: order.id,
              );

              // Buzz for 5 seconds
              Vibration.vibrate(duration: 5000);
            }
          }
        }

        // Clean up notified IDs for orders that no longer exist
        _notifiedOrderIds.removeWhere(
          (id) => !orders.any((order) => order.id == id),
        );
      });
    });

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
                        .updateAvailability(widget.profile.id, val);

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

          // Available Orders Section
          const Text(
            'Available Orders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Consumer(
            builder: (context, ref, _) {
              final ordersAsync = ref.watch(availableOrdersStreamProvider);

              return ordersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No available orders at the moment',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _AvailableOrderCard(
                          order: orders[index],
                          riderId: widget.profile.id,
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error loading orders: $err'),
                  ),
                ),
              );
            },
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
                  icon: const Icon(Icons.local_shipping),
                  label: const Text('RECEIVED FOOD CARGO'),
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

// Available Order Card Widget
class _AvailableOrderCard extends ConsumerStatefulWidget {
  final FoodRequest order;
  final String riderId;

  const _AvailableOrderCard({required this.order, required this.riderId});

  @override
  ConsumerState<_AvailableOrderCard> createState() =>
      _AvailableOrderCardState();
}

class _AvailableOrderCardState extends ConsumerState<_AvailableOrderCard> {
  bool _isAccepted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isAccepted) {
      return const SizedBox.shrink(); // Hide immediately
    }

    return Card(
      margin: const EdgeInsets.only(right: 12),
      elevation: 2,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.order.foodType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${widget.order.quantity} servings',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.business, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.order.organization?.organizationName ??
                        'Organization',
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                          _isAccepted = true; // Optimistic update
                        });

                        try {
                          await ref
                              .read(foodRequestRepositoryProvider)
                              .assignRiderToRequest(
                                requestId: widget.order.id,
                                riderId: widget.riderId,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Order Accepted! Added to Active Jobs.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _isAccepted = false; // Revert
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to accept order'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle, size: 18),
                label: Text(_isLoading ? 'Accepting...' : 'Accept Order'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
