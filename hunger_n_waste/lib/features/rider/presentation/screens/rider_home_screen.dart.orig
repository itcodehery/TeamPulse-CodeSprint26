import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/data/repositories/rider_repository.dart';
import '../../../auth/data/repositories/donor_repository.dart';
import '../../../auth/data/repositories/organization_repository.dart';
import '../../../food_requests/data/repositories/food_request_repository.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'location_camera_screen.dart';
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
        title: Text(
          'Rider Dashboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 24),
        ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Premium Availability Card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAvailable
                    ? [const Color(0xFF2E7D32), const Color(0xFF4CAF50)]
                    : [const Color(0xFF616161), const Color(0xFF9E9E9E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isAvailable ? Colors.green : Colors.grey).withOpacity(
                    0.3,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final newVal = !isAvailable;
                  try {
                    await ref
                        .read(riderRepositoryProvider)
                        .updateAvailability(widget.profile.id, newVal);
                    ref.invalidate(riderProfileStreamProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAvailable ? Icons.bolt : Icons.power_settings_new,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAvailable ? 'ONLINE' : 'OFFLINE',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              isAvailable
                                  ? 'Ready to deliver'
                                  : 'Tap to go online',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 1.2,
                        child: Switch(
                          value: isAvailable,
                          onChanged: (val) async {
                            try {
                              await ref
                                  .read(riderRepositoryProvider)
                                  .updateAvailability(widget.profile.id, val);
                              ref.invalidate(riderProfileStreamProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          activeColor: Colors.white,
                          activeTrackColor: Colors.white.withOpacity(0.4),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.black12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 2. Statistics Overview
          Row(
            children: [
              _buildStatCard(
                context,
                'Deliveries',
                '12',
                Icons.shopping_bag_outlined,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                context,
                'Ratings',
                '4.8',
                Icons.star_outline_rounded,
                Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Available Orders Section
          Text(
            'Available Orders',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Consumer(
            builder: (context, ref, _) {
              final ordersAsync = ref.watch(availableOrdersStreamProvider);

              return ordersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Center(
                        child: Text(
                          'No available orders nearby',
                          style: GoogleFonts.outfit(color: Colors.grey[500]),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 240,
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
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Text('Error: $err'),
              );
            },
          ),

          const SizedBox(height: 32),

          // Active Jobs Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Jobs',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final jobsAsync = ref.watch(riderActiveJobsStreamProvider);
                  return jobsAsync.maybeWhen(
                    data: (jobs) => jobs.isEmpty
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${jobs.length}',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          Consumer(
            builder: (context, ref, _) {
              final jobsAsync = ref.watch(riderActiveJobsStreamProvider);

              return jobsAsync.when(
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delivery_dining_outlined,
                            size: 64,
                            color: Colors.grey[200],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAvailable
                                ? 'No active jobs yet'
                                : 'Go online to see jobs',
                            style: GoogleFonts.outfit(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      return _JobCard(job: jobs[index]);
                    },
                  );
                },
                error: (err, stack) => Center(child: Text('Error')),
                loading: () => const Center(child: CircularProgressIndicator()),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        bool qualityChecked = false;
        bool packagingChecked = false;
        String? imagePath;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                left: 24,
                right: 24,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Color(0xFFFF9800),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup Verification',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Ensure quality standards are met',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Checklist Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: Text(
                            'Food Quality Verified',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Freshness & temp check',
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          value: qualityChecked,
                          activeColor: const Color(0xFFFF9800),
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          onChanged: (val) =>
                              setState(() => qualityChecked = val!),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(height: 1, color: Colors.grey[200]),
                        ),
                        CheckboxListTile(
                          title: Text(
                            'Packaging Intact',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'No spills or damages',
                            style: GoogleFonts.outfit(fontSize: 12),
                          ),
                          value: packagingChecked,
                          activeColor: const Color(0xFFFF9800),
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          onChanged: (val) =>
                              setState(() => packagingChecked = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

<<<<<<< HEAD
                  const Text(
                    'Proof of Pickup',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (imagePath != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(imagePath!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => setState(() => imagePath = null),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LocationCameraScreen(),
                          ),
                        );
                        if (result != null && result is String) {
                          setState(() => imagePath = result);
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Capture Photo Evidence'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
=======
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.camera_rounded, size: 18),
                    label: Text(
                      'Capture Photo (Coming Soon)',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[200]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
>>>>>>> camera
                      ),
                    ),

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: (qualityChecked && packagingChecked)
                          ? () {
                              Navigator.pop(context);
                              _updateStatus(context, ref, 'in_transit');
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'CONFIRM PICKUP',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
<<<<<<< HEAD
        String? imagePath;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 16,
=======
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
>>>>>>> camera
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
<<<<<<< HEAD
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
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Proof of Delivery',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (imagePath != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(imagePath!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => setState(() => imagePath = null),
                            ),
=======
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: Color(0xFF2E7D32),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Handover',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Confirm receiver details',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[500],
>>>>>>> camera
                          ),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LocationCameraScreen(),
                          ),
                        );
                        if (result != null && result is String) {
                          setState(() => imagePath = result);
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Capture Photo Evidence'),
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
<<<<<<< HEAD
            );
          },
=======
              const SizedBox(height: 32),

              TextField(
                controller: nameController,
                style: GoogleFonts.outfit(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Receiver Name',
                  labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                  hintText: 'Who received the order?',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                  ),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 32),

              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.camera_rounded, size: 18),
                label: Text(
                  'Capture Proof (Coming Soon)',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[200]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      Navigator.pop(context);
                      _updateStatus(context, ref, 'completed');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'COMPLETE DELIVERY',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
>>>>>>> camera
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

    final isPending = status == 'pending_pickup';
    final primaryColor = isPending
        ? const Color(0xFFFF9800)
        : const Color(0xFF2E7D32);
    final statusLabel = isPending ? 'PICKUP' : 'IN TRANSIT';

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Order #${job['id'].toString().substring(0, 6).toUpperCase()}',
                  style: GoogleFonts.outfit(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['food_type'],
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${job['quantity']} servings ready for delivery',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lunch_dining_rounded,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Timeline
                _buildTimelineStep(
                  context,
                  title: 'PICKUP FROM',
                  asyncValue: donorAsync,
                  isDonor: true,
                  isActive: isPending,
                  isLast: false,
                ),
                const SizedBox(height: 8),
                _buildTimelineStep(
                  context,
                  title: 'DELIVER TO',
                  asyncValue: orgAsync,
                  isDonor: false,
                  isActive: !isPending,
                  isLast: true,
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    _buildNavigateButton(
                      context,
                      isPending ? donorAsync : orgAsync,
                      primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: () => isPending
                              ? _showPickupModal(context, ref, null, null)
                              : _showDeliveryModal(context, ref, null, null),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isPending ? 'START PICKUP' : 'COMPLETE DELIVERY',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: IconButton(
        onPressed: () {
          locationAsync.whenData((data) {
            if (data != null) {
              try {
                final d = data as dynamic;
                final lat = d.defaultLatitude ?? d.latitude;
                final long = d.defaultLongitude ?? d.longitude;

                if (lat != null && long != null) {
                  _launchMap(lat, long);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location not available'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error: $e');
              }
            }
          });
        },
        icon: Icon(Icons.near_me_rounded, color: color, size: 22),
        tooltip: 'Navigate',
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
    final color = isDonor ? const Color(0xFFFF9800) : const Color(0xFF2E7D32);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? color : Colors.white,
                  border: Border.all(
                    color: isActive ? color : Colors.grey[200]!,
                    width: 2,
                  ),
                ),
                child: isActive
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[100],
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? color : Colors.grey[400],
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  asyncValue.when(
                    data: (data) {
                      if (data == null) {
                        return Text(
                          'Loading details...',
                          style: GoogleFonts.outfit(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        );
                      }

                      final name = isDonor
                          ? 'Donor Location'
                          : (data as dynamic).organizationName as String;
                      final address = isDonor
                          ? (data as dynamic).defaultAddress ?? 'No Address'
                          : (data as dynamic).address as String;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.black87
                                  : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            address,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                    loading: () => Container(
                      width: 140,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    error: (_, __) => Text(
                      'Address unavailable',
                      style: GoogleFonts.outfit(color: Colors.red[300]),
                    ),
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

    return Container(
      width: 300,
      height: 240,
      margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background Decoration
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.restaurant_menu,
                size: 100,
                color: Colors.green.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bolt,
                              size: 14,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'NEW',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF2E7D32),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '刚刚', // Just now
                        style: GoogleFonts.outfit(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.order.foodType,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.order.quantity} servings available',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.order.organization?.organizationName ??
                              'Nearby Org',
                          style: GoogleFonts.outfit(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              Vibration.cancel();
                              setState(() {
                                _isLoading = true;
                                _isAccepted = true;
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
                                      backgroundColor: Color(0xFF2E7D32),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() {
                                    _isAccepted = false;
                                    _isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to accept order'),
                                    ),
                                  );
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Accept & Pickup',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
