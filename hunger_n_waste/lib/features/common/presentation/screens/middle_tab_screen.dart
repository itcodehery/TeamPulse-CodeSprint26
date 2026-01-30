import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/user_enums.dart';
import '../../../posts/presentation/screens/add_screen.dart';
import '../../../food_requests/presentation/screens/donor_contributions_screen.dart';
import '../../../rider/presentation/screens/rider_history_screen.dart';

class MiddleTabScreen extends ConsumerWidget {
  const MiddleTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Route based on user type
    switch (user.userType) {
      case UserType.donor:
        return const DonorContributionsScreen();
      case UserType.rider:
        return const RiderHistoryScreen();
      case UserType.organization:
        return const AddScreen();
    }
  }
}
