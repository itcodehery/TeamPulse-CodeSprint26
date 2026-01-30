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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 24),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Organization Header (More personal)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.volunteer_activism,
                              color: Theme.of(context).primaryColor,
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                              ),
                              Text(
                                'Verified Partner',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. Narrative Request Card (The "Note")
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF7F2), // Warm paper-like color
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF2E8DF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: 32,
                            color: Colors.orange[300],
                          ),
                          const SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: "We are currently looking for ",
                                ),
                                TextSpan(
                                  text: req.foodType,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const TextSpan(text: " to help feed "),
                                TextSpan(
                                  text: "${req.quantity} people",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      ". Your timely contribution would mean the world to us.",
                                ),
                              ],
                            ),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  height: 1.6,
                                  color: Colors.grey[800],
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  req.organization?.address ??
                                      'Location details provided upon acceptance',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[700]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 4. Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _showLocationPickerDialog(req),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border),
                            SizedBox(width: 12),
                            Text(
                              'Accept & Support',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
