import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../food_requests/presentation/providers/active_requests_provider.dart';
import '../../../food_requests/domain/models/food_request.dart';
import '../providers/organizations_provider.dart';
import '../providers/donor_notifications_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../widgets/organization_card.dart';
import 'delivery_options_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _currentPosition;
  bool _isMapReady = false;
  bool _hasMovedToUser = false;
  String _searchQuery = '';
  final Map<String, String> _previousStatuses = {};

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetLocation();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _moveToUser();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _moveToUser() {
    if (_isMapReady && _currentPosition != null && !_hasMovedToUser) {
      _mapController.move(_currentPosition!, 15.0);
      _hasMovedToUser = true;
    }
  }

  void _showStatusNotification(FoodRequest request, String newStatus) {
    final message = _getStatusMessage(newStatus, request);
    NotificationService.showStatusNotification(
      title: 'Donation Status Update',
      body: message,
      payload: request.id,
    );
  }

  String _getStatusMessage(String status, FoodRequest request) {
    switch (status) {
      case 'pendingPickup':
        return 'Rider assigned for ${request.foodType}';
      case 'inTransit':
        return 'Rider picked up ${request.foodType} and is on the way!';
      case 'completed':
        return '${request.foodType} delivered successfully! Thank you for your contribution!';
      case 'cancelled':
        return 'Delivery of ${request.foodType} was cancelled';
      default:
        return 'Status updated for ${request.foodType}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for status changes on donor's contributions
    ref.listen(donorNotificationsProvider, (previous, next) {
      next.whenData((requests) {
        for (var request in requests) {
          final previousStatus = _previousStatuses[request.id];
          final currentStatus = request.status.name;

          if (previousStatus != null && previousStatus != currentStatus) {
            _showStatusNotification(request, currentStatus);
          }

          _previousStatuses[request.id] = currentStatus;
        }
      });
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 40, 16, 0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Explore',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.black87,
                        size: 24,
                      ),
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (mounted) context.go('/login');
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.black87,
                        size: 24,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                51.509364,
                -0.128928,
              ), // Default to London
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapReady: () {
                _isMapReady = true;
                _moveToUser();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hunger_n_waste',
              ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      key: const ValueKey('user_marker'),
                      point: _currentPosition!,
                      width: 60,
                      height: 60,
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30,
                        child: Icon(Icons.person, color: Colors.blue, size: 40),
                      ),
                    ),
                  ...ref
                      .watch(activeRequestsProvider)
                      .when(
                        data: (requests) {
                          return requests
                              .map((req) {
                                final lat = req.latitude;
                                final long = req.longitude;
                                if (lat == 0 && long == 0) return null;

                                return Marker(
                                  key: ValueKey(req.id),
                                  point: LatLng(lat, long),
                                  width: 60,
                                  height: 60,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _showRequestDetails(context, req),
                                    child: Stack(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 50,
                                        ),
                                        Positioned(
                                          right: 8,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2E7D32),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '${req.quantity}',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              })
                              .whereType<Marker>()
                              .toList();
                        },
                        error: (err, stack) => [],
                        loading: () => [],
                      ),
                ],
              ),
            ],
          ),

          // Organization List Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Handle bar
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          // Search bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.outfit(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Search organizations...',
                                hintStyle: GoogleFonts.outfit(
                                  color: Colors.grey[400],
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: Colors.grey[400],
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded),
                                        onPressed: () =>
                                            _searchController.clear(),
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    ref
                        .watch(allOrganizationsProvider)
                        .when(
                          data: (organizations) {
                            final activeRequestsAsync = ref.watch(
                              activeRequestsProvider,
                            );
                            final activeOrgIds =
                                activeRequestsAsync.asData?.value
                                    .map((req) => req.orgId)
                                    .toSet() ??
                                {};

                            // Filter organizations based on search
                            final filteredOrgs = organizations.where((org) {
                              if (_searchQuery.isEmpty) return true;
                              return org.organizationName
                                      .toLowerCase()
                                      .contains(_searchQuery) ||
                                  org.address.toLowerCase().contains(
                                    _searchQuery,
                                  );
                            }).toList();

                            // Sort: Open first, then closed
                            filteredOrgs.sort((a, b) {
                              final aOpen = activeOrgIds.contains(a.id);
                              final bOpen = activeOrgIds.contains(b.id);
                              if (aOpen && !bOpen) return -1;
                              if (!aOpen && bOpen) return 1;
                              return 0;
                            });

                            if (filteredOrgs.isEmpty) {
                              return SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No organizations found',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            return SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final org = filteredOrgs[index];
                                  final isOpen = activeOrgIds.contains(org.id);

                                  return OrganizationCard(
                                    organization: org,
                                    isOpen: isOpen,
                                    onTap: () {
                                      // Move map to organization location if coordinates exist
                                      if (org.latitude != null &&
                                          org.longitude != null) {
                                        _mapController.move(
                                          LatLng(org.latitude!, org.longitude!),
                                          15.0,
                                        );
                                      }
                                    },
                                  );
                                }, childCount: filteredOrgs.length),
                              ),
                            );
                          },
                          error: (err, stack) => SliverToBoxAdapter(
                            child: Center(
                              child: Text('Error loading organizations: $err'),
                            ),
                          ),
                          loading: () => const SliverToBoxAdapter(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),

          // Recenter Button
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'recenter',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _moveToUser,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(BuildContext context, FoodRequest req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.organization?.organizationName ??
                              'Community Partner',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Verified Partner • Active Now',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Text(
                'THE IMPACT'.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: "Help provide "),
                    TextSpan(
                      text: "${req.quantity} servings",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const TextSpan(text: " of "),
                    TextSpan(
                      text: req.foodType,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.solid,
                        decorationColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    const TextSpan(
                      text:
                          " to those in need. Every contribution brings a smile.",
                    ),
                  ],
                ),
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  height: 1.4,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup Address',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                            ),
                          ),
                          Text(
                            req.organization?.address ?? 'Login to see details',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 58,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DeliveryOptionsScreen(request: req),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'ACCEPT & SUPPORT',
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
  }
}
