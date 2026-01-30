import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/location_picker_screen.dart';
import '../../domain/models/user_enums.dart';

class OrganizationRegistrationScreen extends ConsumerStatefulWidget {
  const OrganizationRegistrationScreen({super.key});

  @override
  ConsumerState<OrganizationRegistrationScreen> createState() =>
      _OrganizationRegistrationScreenState();
}

class _OrganizationRegistrationScreenState
    extends ConsumerState<OrganizationRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseController = TextEditingController();
  OrganizationType _selectedType = OrganizationType.ngo;
  LatLng? _selectedLocation;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _licenseController.dispose();
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
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location on the map')),
        );
        return;
      }
      // TODO: Submit info
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing Organization Registration...'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organization Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Organization Name',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter organization name'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<OrganizationType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Organization Type',
                ),
                items: OrganizationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter address'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'License Number (Optional)',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedLocation == null
                      ? 'Pick Location on Map'
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
