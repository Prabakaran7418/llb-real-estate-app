import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/enquiries/screens/enquiry_form_screen.dart';
import '../features/enquiries/screens/enquiry_history_screen.dart';
import '../features/favourites/screens/favourites_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/map/screens/map_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/properties/screens/property_details_screen.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home', // Directly open to the attractive property discovery homepage
    redirect: (context, state) {
      if (!authState.isInitialized) {
        return null;
      }

      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      final publicRoutes = [
        '/home',
        '/map',
        '/login',
        '/register',
        '/forgot-password',
      ];
      final isPublic = publicRoutes.contains(state.matchedLocation) ||
          state.matchedLocation.startsWith('/property/');

      // If user is trying to access private screens without auth
      if (!isAuthenticated && !isPublic) {
        return '/login';
      }

      // If user is already authenticated and on login/register -> redirect to Home
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Authentication Routes (First screen is Login)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main Navigation Shell with Bottom Tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1: Interactive Google Maps
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),

          // Branch 2: Saved / Favourites
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favourites',
                builder: (context, state) => const FavouritesScreen(),
              ),
            ],
          ),

          // Branch 3: Enquiries & Visits History
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/enquiries',
                builder: (context, state) => const EnquiryHistoryScreen(),
              ),
            ],
          ),

          // Branch 4: Profile & Settings
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

      // Property Details (Full screen on root navigator)
      GoRoute(
        path: '/property/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final propertyId = state.pathParameters['id'] ?? '';
          return PropertyDetailsScreen(propertyId: propertyId);
        },
      ),

      // Schedule Site Visit & Enquiry (Full screen on root navigator)
      GoRoute(
        path: '/enquire/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final propertyId = state.pathParameters['id'] ?? '';
          return EnquiryFormScreen(propertyId: propertyId);
        },
      ),

      // Admin Dashboard (Full screen on root navigator)
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});
