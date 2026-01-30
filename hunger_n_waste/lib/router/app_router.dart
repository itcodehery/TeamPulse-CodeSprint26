import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/posts/presentation/screens/add_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/common/presentation/widgets/scaffold_with_navbar.dart';
import '../features/auth/presentation/screens/user_type_selection_screen.dart';
import '../features/auth/presentation/screens/donor_registration_screen.dart';
import '../features/auth/presentation/screens/organization_registration_screen.dart';
import '../features/auth/presentation/screens/rider_registration_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                builder: (context, state) => const AddScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/auth/select-type',
        builder: (context, state) => const UserTypeSelectionScreen(),
      ),
      GoRoute(
        path: '/auth/register/donor',
        builder: (context, state) => const DonorRegistrationScreen(),
      ),
      GoRoute(
        path: '/auth/register/organization',
        builder: (context, state) => const OrganizationRegistrationScreen(),
      ),
      GoRoute(
        path: '/auth/register/rider',
        builder: (context, state) => const RiderRegistrationScreen(),
      ),
    ],
  );
});
