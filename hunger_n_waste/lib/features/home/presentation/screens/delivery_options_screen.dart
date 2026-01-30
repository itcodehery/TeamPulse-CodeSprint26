import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../food_requests/domain/models/food_request.dart';
import '../../../food_requests/data/repositories/food_request_repository.dart';
import '../../../food_requests/presentation/providers/active_requests_provider.dart';
import '../../../../core/widgets/location_picker_screen.dart';

enum DeliveryType { selfDelivery, deliveryService }

class DeliveryOptionsScreen extends ConsumerStatefulWidget {
  final FoodRequest request;

  const DeliveryOptionsScreen({super.key, required this.request});

  @override
  ConsumerState<DeliveryOptionsScreen> createState() =>
      _DeliveryOptionsScreenState();
}

class _DeliveryOptionsScreenState extends ConsumerState<DeliveryOptionsScreen> {
  DeliveryType? _selectedDeliveryType;
  LatLng? _pickupLocation;
  bool _isProcessing = false;

  static const double _deliveryCharge = 50.0;

  Future<void> _handleConfirm() async {
    if (_selectedDeliveryType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery option'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // For delivery service, we need a pickup location
    if (_selectedDeliveryType == DeliveryType.deliveryService) {
      if (_pickupLocation == null) {
        await _showLocationPickerDialog();
        if (_pickupLocation == null) return; // User cancelled
      }
    }

    setState(() => _isProcessing = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Please log in');
      }

      await ref
          .read(foodRequestRepositoryProvider)
          .fulfillRequest(
            requestId: widget.request.id,
            donorId: user.id,
            deliveryType: _selectedDeliveryType == DeliveryType.selfDelivery
                ? 'self'
                : 'service',
            pickupLocation: _pickupLocation,
          );

      // Refresh the active requests
      ref.invalidate(activeRequestsProvider);

      if (mounted) {
        Navigator.of(context).pop(); // Go back to home screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedDeliveryType == DeliveryType.selfDelivery
                  ? 'Thank you! Please deliver to the organization directly.'
                  : 'Thank you! Rider assigned and will pick up soon.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showLocationPickerDialog() async {
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

    if (result == null) return;

    if (result == 'current') {
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _pickupLocation = LatLng(position.latitude, position.longitude);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not get current location. Please enable GPS.',
              ),
            ),
          );
        }
      }
    } else if (result == 'select') {
      final selectedLocation = await Navigator.of(context).push<LatLng>(
        MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
      );

      if (selectedLocation != null) {
        setState(() {
          _pickupLocation = selectedLocation;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Donation Options',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Request Summary Section (matching modal UI)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organization Header
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
                      // Quantity Badge
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

                  // Request Narrative
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

                  // Location Context
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
                                'Dropoff Location',
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(height: 8, color: Colors.grey[100]),

            // Delivery Options Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Delivery Method',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Self-Delivery Option
                  _DeliveryOptionCard(
                    icon: Icons.directions_walk_rounded,
                    title: 'Self-Delivery',
                    subtitle: 'Drop food directly to the organization',
                    price: 'FREE',
                    isSelected:
                        _selectedDeliveryType == DeliveryType.selfDelivery,
                    onTap: () {
                      setState(() {
                        _selectedDeliveryType = DeliveryType.selfDelivery;
                        _pickupLocation = null; // Clear pickup location
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Delivery Service Option
                  _DeliveryOptionCard(
                    icon: Icons.delivery_dining_rounded,
                    title: 'Delivery Service',
                    subtitle: 'Our rider will pick up and deliver',
                    price: '₹${_deliveryCharge.toStringAsFixed(0)}',
                    isSelected:
                        _selectedDeliveryType == DeliveryType.deliveryService,
                    onTap: () {
                      setState(() {
                        _selectedDeliveryType = DeliveryType.deliveryService;
                      });
                    },
                  ),

                  // Pickup Location Selection (conditional)
                  if (_selectedDeliveryType ==
                      DeliveryType.deliveryService) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Pickup Location',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _showLocationPickerDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _pickupLocation != null
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _pickupLocation != null
                                  ? Icons.check_circle
                                  : Icons.add_location_alt_rounded,
                              color: _pickupLocation != null
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _pickupLocation != null
                                    ? 'Pickup location selected'
                                    : 'Tap to select pickup location',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: _pickupLocation != null
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontWeight: _pickupLocation != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: 58,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _isProcessing ? null : _handleConfirm,
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Confirm Donation',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.85)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.85)
                : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.15)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black87,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (price == 'FREE'
                          ? Theme.of(context).primaryColor
                          : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
