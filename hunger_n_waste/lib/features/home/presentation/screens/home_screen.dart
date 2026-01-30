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

import 'package:supabase_flutter/supabase_flutter.dart';

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
            initialChildSize: 0.3,
            minChildSize: 0.1,
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
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Organizations list
                    Expanded(
                      child: ref
                          .watch(allOrganizationsProvider)
                          .when(
                            data: (organizations) {
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

                              if (filteredOrgs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                );
                              }

                              return ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredOrgs.length,
                                itemBuilder: (context, index) {
                                  final org = filteredOrgs[index];
                                  return OrganizationCard(
                                    organization: org,
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
                                },
                              );
                            },
                            error: (err, stack) => Center(
                              child: Text('Error loading organizations: $err'),
                            ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
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
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                req.foodType,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (req.organization != null)
                Text(
                  'Provided by: ${req.organization!.organizationName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.people),
                  const SizedBox(width: 8),
                  Text('${req.quantity} people can be fed'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req.organization?.address ?? 'Unknown Location',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _donateAndFulfill(req),
                  icon: const Icon(Icons.volunteer_activism),
                  label: const Text('Donate & Fulfill'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _donateAndFulfill(FoodRequest req) async {
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
      // 3. Update Status via Repo (Need a method for this)
      // Since I haven't added `updateRequest` to Repo yet, I'll do it via basic client or add it.
      // Better to add it to Repo. But for now, let's do direct update or assume I'll add it.
      // Let's add standard Supabase update here for speed or refactor repo in next step.
      // I'll update it directly here for now to verify, but ideally Repo should handle it.

      // 3. Find and Assign Rider (Simulation)
      // Query "rider_profiles" where is_available = true
      final availableRiders = await Supabase.instance.client
          .from('rider_profiles')
          .select()
          .eq('is_available', true)
          .limit(1);

      String? assignedRiderId;
      if (availableRiders.isNotEmpty) {
        assignedRiderId = availableRiders.first['id'] as String;
      }

      // 4. Update Status and Assign Rider
      await Supabase.instance.client
          .from('food_requests')
          .update({
            'status': 'pending_pickup',
            'donor_id': user.id,
            'rider_id': assignedRiderId, // Can be null if no riders available
          })
          .eq('id', req.id);

      // If rider assigned, set them to unavailable (optional, but good for demo)
      if (assignedRiderId != null) {
        // await Supabase.instance.client.from('rider_profiles').update({
        //   'is_available': false,
        // }).eq('id', assignedRiderId);
        // Keeping them available for simplicity in demo
      }

      // 5. Refresh List
      // ignore: unused_result
      ref.refresh(activeRequestsProvider);

      if (mounted) {
        final msg = assignedRiderId != null
            ? 'Thank you! Rider assigned.'
            : 'Thank you! Searching for a rider...';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
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
