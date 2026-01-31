import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Default to some central location (e.g., city center) if no current location logic yet
  // For now, let's pick a default (e.g., New York or just 0,0) and let user scroll.
  // Better yet, maybe start at 0,0 but zoomed out?
  // Or just pick a random known city for generic startup.
  LatLng _selectedLocation = const LatLng(
    12.9716,
    77.5946,
  ); // Bangalore default
  final MapController _mapController = MapController();
  bool _isLocating = false;

  Future<void> _locateMe() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final latLng = LatLng(position.latitude, position.longitude);

        setState(() {
          _selectedLocation = latLng;
        });

        _mapController.move(latLng, 15.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(_selectedLocation);
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _selectedLocation,
          initialZoom: 13.0,
          onTap: (tapPosition, point) {
            setState(() {
              _selectedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.hunger_n_waste',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'locate_me',
            onPressed: _isLocating ? null : _locateMe,
            backgroundColor: Theme.of(context).primaryColor,
            child: _isLocating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'confirm_location',
            onPressed: () {
              Navigator.of(context).pop(_selectedLocation);
            },
            child: const Icon(Icons.check),
          ),
        ],
      ),
    );
  }
}
