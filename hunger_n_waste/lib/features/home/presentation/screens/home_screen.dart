import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

import '../../../food_requests/presentation/providers/active_requests_provider.dart';
import '../../../food_requests/domain/models/food_request.dart';
import '../providers/organizations_provider.dart';
import '../widgets/organization_card.dart';
import '../../../../core/widgets/location_picker_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../food_requests/data/repositories/food_request_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Explore',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
        ],
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
                                // Use request's own location (from food_requests table)
                                final lat = req.latitude;
                                final long = req.longitude;

                                // Skip if location is invalid
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
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '${req.quantity}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
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
            initialChildSize: 0.35,
            minChildSize: 0.18,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search organizations...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
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
                                          style: GoogleFonts.poppins(
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
            bottom: 180,
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
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Header: Org Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[100]!,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.grey[50],
                            child: Icon(
                              Icons.volunteer_activism_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.organization?.organizationName ??
                                    'Community Organization',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified Partner',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Status Badge (Quantity)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${req.quantity} Servings',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 3. The Request Narrative
                    Text(
                      'Requesting help with'.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: "We are currently looking for "),
                          TextSpan(
                            text: req.foodType,
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                            ),
                          ),
                          const TextSpan(text: " to help feed "),
                          TextSpan(
                            text: "${req.quantity} people",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text: ". Your contribution makes a direct impact.",
                          ),
                        ],
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        height: 1.4,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Location Context
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pickup Location',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  req.organization?.address ??
                                      'Location details provided upon acceptance',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey[800],
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

                    // 5. Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Colors.black, // High contrast, professional
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _showLocationPickerDialog(req),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Accept & Support',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLocationPickerDialog(FoodRequest req) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pickup Location'),
          content: const Text('Where should the rider pick up the donation?'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop('current'),
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop('select'),
              icon: const Icon(Icons.map),
              label: const Text('Select on Map'),
            ),
          ],
        );
      },
    );

    if (result == null) return; // User cancelled

    LatLng? pickupLocation;

    if (result == 'current') {
      // Use current location
      if (_currentPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Current location not available. Please enable GPS.',
              ),
            ),
          );
        }
        return;
      }
      pickupLocation = _currentPosition;
    } else if (result == 'select') {
      // Navigate to location picker screen
      final selectedLocation = await Navigator.of(context).push<LatLng>(
        MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
      );

      if (selectedLocation == null) return; // User cancelled
      pickupLocation = selectedLocation;
    }

    if (pickupLocation != null) {
      await _donateAndFulfill(req, pickupLocation);
    }
  }

  Future<void> _donateAndFulfill(FoodRequest req, LatLng pickupLocation) async {
    // 1. Check Auth logic (assuming already logged in)
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in')));
      return;
    }

    // 2. Optimistic Update / Loader
    Navigator.pop(context); // Close sheet
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Processing donation...')));

    try {
      // 3. Use Repository to fulfill request
      // TODO: Update this to pass the pickup location to the repository
      await ref
          .read(foodRequestRepositoryProvider)
          .fulfillRequest(
            requestId: req.id,
            donorId: user.id,
            pickupLocation: pickupLocation,
          );

      // 4. Refresh List
      // ignore: unused_result
      ref.refresh(activeRequestsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Donation confirmed & Rider assigned.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
