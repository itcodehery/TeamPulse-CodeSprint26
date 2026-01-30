import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
      final orgProfileAsync = await ref.read(
        currentOrganizationProvider.future,
      );

      if (orgProfileAsync == null) {
        throw Exception('Organization profile not found. Please log in again.');
      }

      if (orgProfileAsync.latitude == null ||
          orgProfileAsync.longitude == null) {
        throw Exception(
          'Organization location is missing. Please update your profile.',
        );
      }

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
          SnackBar(
            content: Text(
              'Request posted successfully!',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _quantityController.clear();
        setState(() {
          _selectedFoodType = _foodTypes.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(currentOrganizationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Post Request',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: orgAsync.when(
        data: (org) {
          if (org == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_person_rounded,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Only Organizations can post requests.',
                    style: GoogleFonts.outfit(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'What can you\nshare today?',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in the details below to reach our donors.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Food Type Field
                  _buildSectionLabel('FOOD CATEGORY'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFoodType,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        items: _foodTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null)
                            setState(() => _selectedFoodType = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quantity Field
                  _buildSectionLabel('QUANTITY (SERVINGS)'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _quantityController,
                    style: GoogleFonts.outfit(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'e.g. 50',
                      hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                      prefixIcon: Icon(
                        Icons.people_alt_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter quantity';
                      if (int.tryParse(value) == null || int.parse(value) <= 0)
                        return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 48),

                  // Submit Button
                  SizedBox(
                    height: 58,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'POST REQUEST',
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
            ),
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
        letterSpacing: 1.5,
      ),
    );
  }
}
