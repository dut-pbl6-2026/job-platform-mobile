import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../session/auth_session.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/main_navigation_screen.dart';
import '../../features/jobs/presentation/job_detail_screen.dart';
import '../../features/jobs/presentation/job_list_screen.dart';
import '../../features/applications/presentation/application_detail_screen.dart';
import '../../features/applications/presentation/application_history_screen.dart';
import '../../features/applications/presentation/apply_job_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/splash/splash_screen.dart';

/// Route names constants
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String jobs = '/jobs';
  static const String jobDetail = '/jobs/:id';
  static const String applyJob = '/jobs/:id/apply';
  static const String applications = '/applications';
  static const String applicationDetail = '/applications/:id';
  static const String profile = '/profile';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  /// Public routes that do not require authentication.
  static const List<String> publicRoutes = [
    splash,
    login,
    register,
    jobs,
    forgotPassword,
    resetPassword,
  ];
}

/// GoRouter configuration for Navigation Structure
/// Includes auth guard redirect and reactive session listener (MOB-01).
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: AuthSession.instance,
    redirect: (context, state) {
      final isAuthenticated = AuthSession.instance.isAuthenticated;
      final currentPath = state.matchedLocation;

      // /jobs and /jobs/:id are public, but /jobs/:id/apply requires authentication!
      final isApplyRoute = currentPath.endsWith('/apply');
      final isPublicRoute =
          AppRoutes.publicRoutes.contains(currentPath) ||
          (currentPath.startsWith('/jobs') && !isApplyRoute);

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
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',
        builder: (context, state) =>
            ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.jobs,
                name: 'jobs',
                builder: (context, state) => const JobListScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: ':id',
                    name: 'job-detail',
                    builder: (context, state) {
                      final jobId = state.pathParameters['id'] ?? '';
                      return JobDetailScreen(jobId: jobId);
                    },
                    routes: [
                      GoRoute(
                        parentNavigatorKey: _rootNavigatorKey,
                        path: 'apply',
                        name: 'apply-job',
                        builder: (context, state) {
                          final jobId = state.pathParameters['id'] ?? '';
                          final extra = state.extra as Map<String, dynamic>?;
                          return ApplyJobScreen(
                            jobId: jobId,
                            jobTitle: extra?['title'] ?? 'Vị trí tuyển dụng',
                            companyName: extra?['company'] ?? 'Doanh nghiệp',
                            companyLogo: extra?['logo'],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.applications,
                name: 'applications',
                builder: (context, state) => const ApplicationHistoryScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: ':id',
                    name: 'application-detail',
                    builder: (context, state) {
                      final appId = state.pathParameters['id'] ?? '';
                      return ApplicationDetailScreen(applicationId: appId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
