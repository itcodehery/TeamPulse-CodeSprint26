import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart'; // For logout or nav
import '../../data/repositories/food_request_repository.dart';
import '../../domain/models/food_request.dart';

class OrganizationHomeScreen extends ConsumerStatefulWidget {
  const OrganizationHomeScreen({super.key});

  @override
  ConsumerState<OrganizationHomeScreen> createState() =>
      _OrganizationHomeScreenState();
}

class _OrganizationHomeScreenState
    extends ConsumerState<OrganizationHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // Should not happen if guarded, but safe fallback
      return const Scaffold(body: Center(child: Text('Not Authenticated')));
    }
    final orgId = user.id;
    final repo = ref.watch(foodRequestRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<FoodRequest>>(
        stream: repo.watchRequestsByOrgId(orgId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!;
          if (requests.isEmpty) {
            return const Center(child: Text('No requests yet. Create one!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(
                    req.foodType,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Status: ${req.status.name.toUpperCase()}\nQuantity: ${req.quantity} people',
                  ),
                  isThreeLine: true,
                  trailing: _buildStatusIcon(req.status),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.go('/add');
        },
        label: const Text('New Request'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusIcon(FoodRequestStatus status) {
    switch (status) {
      case FoodRequestStatus.open:
        return const Icon(Icons.check_circle_outline, color: Colors.green);
      case FoodRequestStatus.active:
        return const Icon(Icons.local_dining, color: Colors.teal);
      case FoodRequestStatus.pendingPickup:
        return const Icon(Icons.access_time, color: Colors.orange);
      case FoodRequestStatus.inTransit:
        return const Icon(Icons.delivery_dining, color: Colors.blue);
      case FoodRequestStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.grey);
      case FoodRequestStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.red);
    }
  }
}
