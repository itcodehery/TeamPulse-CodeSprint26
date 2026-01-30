import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/user_role_provider.dart';
import '../../../posts/presentation/screens/add_screen.dart';
import '../../../food_requests/presentation/screens/donor_contributions_screen.dart';

class MiddleTabScreen extends ConsumerWidget {
  const MiddleTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(currentUserRoleProvider);

    return roleAsync.when(
      data: (role) {
        if (role == 'donor') {
          return const DonorContributionsScreen();
        }
        return const AddScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const AddScreen(), // Default fallback
    );
  }
}
