import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/providers/current_organization_provider.dart';
import '../../../food_requests/data/repositories/food_request_repository.dart';

class AddScreen extends ConsumerStatefulWidget {
  const AddScreen({super.key});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  String _selectedFoodType = 'Veg Meals';
  bool _isLoading = false;

  final List<String> _foodTypes = [
    'Veg Meals',
    'Non-Veg Meals',
    'Groceries',
    'Snacks',
    'Other',
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Get Current Organization Profile for location and ID
      final orgProfileAsync = await ref.read(
        currentOrganizationProvider.future,
      );

      if (orgProfileAsync == null) {
        throw Exception('Organization profile not found. Please log in again.');
      }

      // 2. Validate Location
      if (orgProfileAsync.latitude == null ||
          orgProfileAsync.longitude == null) {
        throw Exception(
          'Organization location is missing. Please update your profile.',
        );
      }

      // 3. Create Request
      await ref
          .read(foodRequestRepositoryProvider)
          .createRequest(
            orgId: orgProfileAsync.id,
            foodType: _selectedFoodType,
            quantity: int.parse(_quantityController.text),
            latitude: orgProfileAsync.latitude!,
            longitude: orgProfileAsync.longitude!,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request posted successfully!')),
        );
        // Clear form
        _quantityController.clear();
        setState(() {
          _selectedFoodType = _foodTypes.first;
        });

        // Return to Home (Explore) tab to see the pin
        // Using go_router logic or simple bottom nav switch if implemented
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch to ensure we can load the profile, though we read it on submit
    final orgAsync = ref.watch(currentOrganizationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Food Request')),
      body: orgAsync.when(
        data: (org) {
          if (org == null) {
            return const Center(
              child: Text('Only Organizations can post requests.'),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Post a new request',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // Food Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedFoodType,
                    decoration: const InputDecoration(
                      labelText: 'Food Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fastfood),
                    ),
                    items: _foodTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedFoodType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantity Input
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (No. of people/meals)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                      hintText: 'e.g. 50',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Please enter a valid positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Post Request'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
