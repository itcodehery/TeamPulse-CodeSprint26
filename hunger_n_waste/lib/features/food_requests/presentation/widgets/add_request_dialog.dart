import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/food_request_repository.dart';
import '../../../auth/data/repositories/organization_repository.dart';

class AddRequestDialog extends ConsumerStatefulWidget {
  final String orgId;

  const AddRequestDialog({super.key, required this.orgId});

  @override
  ConsumerState<AddRequestDialog> createState() => _AddRequestDialogState();
}

class _AddRequestDialogState extends ConsumerState<AddRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _foodTypeController = TextEditingController();
  final _quantityController = TextEditingController(text: '20'); // Default
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final requestRepo = ref.read(foodRequestRepositoryProvider);
        final orgRepo = ref.read(organizationRepositoryProvider);

        // Fetch Org Profile to get location
        final profile = await orgRepo.getProfile(widget.orgId);
        if (profile == null) throw Exception('Organization Profile not found');
        if (profile.latitude == null || profile.longitude == null) {
          throw Exception('Organization location not set');
        }

        await requestRepo.createRequest(
          orgId: widget.orgId,
          foodType: _foodTypeController.text.trim(),
          quantity: int.parse(_quantityController.text.trim()),
          latitude: profile.latitude!,
          longitude: profile.longitude!,
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request Created Successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Food Request'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _foodTypeController,
                decoration: const InputDecoration(
                  labelText: 'Food Type (e.g. Veg Meals)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (No. of people)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null) return 'Must be a number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? _submit : null,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
