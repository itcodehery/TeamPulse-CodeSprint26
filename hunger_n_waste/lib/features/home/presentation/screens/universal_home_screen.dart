import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/user_enums.dart';
import 'home_screen.dart'; // Donor Home
import '../../../food_requests/presentation/screens/organization_home_screen.dart';
import '../../../rider/presentation/screens/rider_home_screen.dart';

class UniversalHomeScreen extends ConsumerWidget {
  const UniversalHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      // Fallback or loading state
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    switch (user.userType) {
      case UserType.organization:
        return const OrganizationHomeScreen();
      case UserType.rider:
        return const RiderHomeScreen();
      case UserType.donor:
        return const HomeScreen();
    }
  }
}
