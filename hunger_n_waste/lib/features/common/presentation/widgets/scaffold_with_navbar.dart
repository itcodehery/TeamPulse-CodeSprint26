import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/user_enums.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userType = user?.userType ?? UserType.donor;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: Theme.of(context).primaryColor.withOpacity(0.12),
        selectedIndex: navigationShell.currentIndex,
        height: 72,
        destinations: [
          _buildNavItem(
            icon: Icons.home_rounded,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            isSelected: navigationShell.currentIndex == 0,
          ),
          if (userType == UserType.donor)
            _buildNavItem(
              icon: Icons.volunteer_activism_rounded,
              activeIcon: Icons.volunteer_activism_rounded,
              label: 'Support',
              isSelected: navigationShell.currentIndex == 1,
            )
          else if (userType == UserType.organization)
            _buildNavItem(
              icon: Icons.add_box_rounded,
              activeIcon: Icons.add_box_rounded,
              label: 'Post',
              isSelected: navigationShell.currentIndex == 1,
            )
          else
            _buildNavItem(
              icon: Icons.history_rounded,
              activeIcon: Icons.history_rounded,
              label: 'History',
              isSelected: navigationShell.currentIndex == 1,
            ),
          _buildNavItem(
            icon: Icons.person_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            isSelected: navigationShell.currentIndex == 2,
          ),
        ],
        onDestinationSelected: _goBranch,
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
  }) {
    return NavigationDestination(
      icon: Icon(icon, color: Colors.grey[600], size: 24),
      selectedIcon: Icon(activeIcon, color: const Color(0xFF2E7D32), size: 26),
      label: label,
    );
  }
}
