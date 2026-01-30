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
import '../features/food_requests/presentation/screens/organization_home_screen.dart';
import '../features/rider/presentation/screens/rider_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_state_notifier.dart';

final authStateNotifierProvider = Provider<AuthStateNotifier>((ref) {
  return AuthStateNotifier();
});

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final authNotifier = ref.watch(authStateNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final isLoggedIn = session != null;

      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation.startsWith('/auth/');

      // If not logged in and trying to access protected routes
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on login/auth pages, redirect to appropriate home
      if (isLoggedIn && isLoggingIn) {
        try {
          final userId = session.user.id;
          final profileResponse = await supabase
              .from('profiles')
              .select('user_type')
              .eq('id', userId)
              .maybeSingle();

          if (profileResponse != null) {
            final userType = profileResponse['user_type'] as String;
            if (userType == 'organization') {
              return '/organization-home';
            } else if (userType == 'rider') {
              return '/rider-home';
            } else {
              return '/home';
            }
          }
        } catch (e) {
          // If error fetching profile, go to home
          return '/home';
        }
      }

      return null; // No redirect needed
    },
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
      GoRoute(
        path: '/organization-home',
        builder: (context, state) => const OrganizationHomeScreen(),
      ),
      GoRoute(
        path: '/rider-home',
        builder: (context, state) => const RiderHomeScreen(),
      ),
    ],
  );
});
