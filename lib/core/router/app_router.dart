import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../session/auth_session.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/splash/splash_screen.dart';

/// Route names constants
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  /// Public routes that do not require authentication.
  static const List<String> publicRoutes = [splash, login, register];
}

/// GoRouter configuration for Navigation Structure
/// Includes auth guard redirect and reactive session listener (MOB-01).
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: AuthSession.instance,
    redirect: (context, state) {
      final isAuthenticated = AuthSession.instance.isAuthenticated;
      final currentPath = state.matchedLocation;
      final isPublicRoute = AppRoutes.publicRoutes.contains(currentPath);

      // Unauthenticated users trying to access private routes → login
      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      // Authenticated users on login/register → redirect to home
      if (isAuthenticated &&
          (currentPath == AppRoutes.login ||
              currentPath == AppRoutes.register)) {
        return AppRoutes.home;
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
