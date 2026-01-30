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
import 'package:url_launcher/url_launcher.dart';
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

      next.whenData((orders) async {
        for (var order in orders) {
          // Only notify for orders we haven't notified about yet
          if (!_notifiedOrderIds.contains(order.id)) {
            _notifiedOrderIds.add(order.id);

            // Don't notify on initial load (when previous doesn't have data yet)
            // We check if previous value had data to avoid notification on app start
            if (previous?.hasValue == true) {
              NotificationService.showStatusNotification(
                title: 'New Order Available!',
                body:
                    '${order.foodType} - ${order.quantity} servings from ${order.organization?.organizationName ?? "nearby"}',
                payload: order.id,
              );

              // Buzz for 5 seconds logic
              if (await Vibration.hasVibrator()) {
                Vibration.vibrate(duration: 5000);
              }
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

  Future<void> _launchMap(double lat, double long) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$long',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $uri');
    }
  }

  void _showPickupModal(
    BuildContext context,
    WidgetRef ref,
    double? lat,
    double? long,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool qualityChecked = false;
        bool packagingChecked = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.orange,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup Verification',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verify order details before pickup',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Checklist
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('Food Quality Verified'),
                          subtitle: const Text(
                            'Freshness and temperature check',
                          ),
                          value: qualityChecked,
                          activeColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onChanged: (val) =>
                              setState(() => qualityChecked = val!),
                        ),
                        const Divider(height: 1),
                        CheckboxListTile(
                          title: const Text('Packaging Intact'),
                          subtitle: const Text('No spills or damages'),
                          value: packagingChecked,
                          activeColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onChanged: (val) =>
                              setState(() => packagingChecked = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Proof of Pickup',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: null, // Disabled for now
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Capture Photo (Coming Soon)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: (qualityChecked && packagingChecked)
                        ? () {
                            Navigator.pop(context);
                            _updateStatus(context, ref, 'in_transit');
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'CONFIRM PICKUP',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeliveryModal(
    BuildContext context,
    WidgetRef ref,
    double? lat,
    double? long,
  ) {
    final nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Handover',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Confirm receiver details',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Receiver Name',
                  hintText: 'Who received the order?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Proof of Delivery',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: null, // Disabled
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Capture Photo (Coming Soon)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    Navigator.pop(context);
                    _updateStatus(context, ref, 'completed');
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'CONFIRM DELIVERY',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = job['status'] as String;
    final orgId = job['org_id'] as String;
    final donorId = job['donor_id'] as String?;

    final orgAsync = ref.watch(organizationProfileProvider(orgId));
    final donorAsync = donorId != null
        ? ref.watch(donorProfileProvider(donorId))
        : const AsyncValue<dynamic>.data(null);

    // Dynamic Colors based on status
    final isPending = status == 'pending_pickup';
    final primaryColor = isPending ? Colors.orange : Colors.green;
    final statusText = isPending ? 'PICKUP PENDING' : 'IN TRANSIT';

    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 4),
                Text(
                  'Qty: ${job['quantity']}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Title
                Text(
                  job['food_type'],
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 24),

                // Timeline View
                _buildTimelineStep(
                  context,
                  title: 'PICKUP',
                  asyncValue: donorAsync,
                  isDonor: true,
                  isActive: isPending,
                  isLast: false,
                ),
                _buildTimelineStep(
                  context,
                  title: 'DROPOFF',
                  asyncValue: orgAsync,
                  isDonor: false,
                  isActive: !isPending, // Active if in transit
                  isLast: true,
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Actions
                if (status == 'pending_pickup') ...[
                  Row(
                    children: [
                      _buildNavigateButton(context, donorAsync, Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _showPickupModal(context, ref, null, null),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Start Pickup'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (status == 'in_transit') ...[
                  Row(
                    children: [
                      _buildNavigateButton(context, orgAsync, Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _showDeliveryModal(context, ref, null, null),
                          icon: const Icon(Icons.done_all),
                          label: const Text('Complete Delivery'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigateButton(
    BuildContext context,
    AsyncValue locationAsync,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () {
          locationAsync.whenData((data) {
            if (data != null) {
              try {
                final d = data as dynamic;
                final lat =
                    d.defaultLatitude ??
                    d.latitude; // handle both models loosely
                final long = d.defaultLongitude ?? d.longitude;

                if (lat != null && long != null) {
                  _launchMap(lat, long);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location not available')),
                  );
                }
              } catch (e) {
                debugPrint('Error: $e');
              }
            }
          });
        },
        icon: Icon(Icons.navigation_outlined, color: color),
        tooltip: 'Navigate',
        style: IconButton.styleFrom(padding: const EdgeInsets.all(12)),
      ),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required String title,
    required AsyncValue asyncValue,
    required bool isDonor,
    required bool isActive,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? (isDonor ? Colors.orange : Colors.green)
                      : Colors.grey[300],
                  border: isActive
                      ? null
                      : Border.all(color: Colors.grey[400]!, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.black87 : Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  asyncValue.when(
                    data: (data) {
                      if (data == null)
                        return Text(
                          'Loading info...',
                          style: TextStyle(color: Colors.grey[400]),
                        );

                      if (isDonor) {
                        final d = data as dynamic;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'From Donor',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              d.defaultAddress ?? 'No Address',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      } else {
                        final o = data as dynamic;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.organizationName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              o.address,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      }
                    },
                    loading: () => Container(
                      width: 100,
                      height: 10,
                      color: Colors.grey[100],
                    ),
                    error: (_, __) => const Text('Error loading info'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
                        // Cancel any ongoing vibration when user interacts
                        Vibration.cancel();

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
                                  'Order Accepted! Proceed to Pickup.',
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
                label: Text(_isLoading ? 'Accepting...' : 'Accept & Pickup'),
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
