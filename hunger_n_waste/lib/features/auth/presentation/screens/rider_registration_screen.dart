import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/location_picker_screen.dart';

class RiderRegistrationScreen extends ConsumerStatefulWidget {
  const RiderRegistrationScreen({super.key});

  @override
  ConsumerState<RiderRegistrationScreen> createState() =>
      _RiderRegistrationScreenState();
}

class _RiderRegistrationScreenState
    extends ConsumerState<RiderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _vehicleTypeController =
      TextEditingController(); // Could be dropdown: Bike, Car, Van
  final _vehicleNumberController = TextEditingController();
  LatLng? _selectedLocation; // Initial location

  @override
  void dispose() {
    _nameController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Riders might not strictly need a static location, but good to have initial
      // If the user wants location picker for everyone, we include it.
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select your current location/base on the map',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing Rider Registration...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rider Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Type (e.g. Bike, Scooter)',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter vehicle type'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(labelText: 'Vehicle Number'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter vehicle number'
                    : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedLocation == null
                      ? 'Pick Current Location / Home Base'
                      : 'Location Selected: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                ),
                trailing: const Icon(Icons.map),
                onTap: _pickLocation,
              ),
              const Divider(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Complete Registration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
