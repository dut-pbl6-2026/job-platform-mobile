import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../session/auth_session.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/cv/presentation/create_cv_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/main_navigation_screen.dart';
import '../../features/jobs/presentation/job_detail_screen.dart';
import '../../features/jobs/presentation/job_list_screen.dart';
import '../../features/jobs/presentation/search_screen.dart';
import '../../features/applications/presentation/application_detail_screen.dart';
import '../../features/applications/presentation/application_history_screen.dart';
import '../../features/applications/presentation/apply_job_screen.dart';
import '../../features/notifications/presentation/notification_screen.dart';
import '../../features/profile/presentation/profile_detail_screen.dart';
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
  static const String search = '/search';
  static const String jobDetail = '/jobs/:id';
  static const String applyJob = '/jobs/:id/apply';
  static const String applications = '/applications';
  static const String applicationDetail = '/applications/:id';
  static const String profile = '/profile';
  static const String profileDetail = '/profile/detail';
  static const String notifications = '/notifications';
  static const String createCv = '/create-cv';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String recruiterJobs = '/recruiter/jobs';

  /// Public routes that do not require authentication.
  static const List<String> publicRoutes = [
    splash,
    login,
    register,
    jobs,
    search,
    forgotPassword,
    resetPassword,
  ];
}

/// GoRouter configuration for Navigation Structure
/// Includes role-based route guards and reactive session listener (MOB-01-01, MOB-01-07, AUTH-01-03, AUTH-01-06).
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
      final resolvedRole = AuthSession.instance.resolvedRole;
      final currentPath = state.matchedLocation;

      final isApplyRoute = currentPath.endsWith('/apply');
      final isRecruiterRoute = currentPath.startsWith('/recruiter');
      final isApplicationRoute = currentPath.startsWith('/applications');
      final isCreateCvRoute = currentPath == AppRoutes.createCv;

      // /jobs and /jobs/:id are public browsing routes, but /jobs/:id/apply requires authentication and candidate role!
      final isPublicRoute =
          AppRoutes.publicRoutes.contains(currentPath) ||
          (currentPath.startsWith('/jobs') && !isApplyRoute);

      // 1. Unauthenticated users trying to access private/protected routes → redirect to login
      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      // 2. Authenticated users on login/register/forgot/reset:
      // If role is valid, redirect to home. If role is unknown or missing, fail closed (stay on login/deny access).
      if (isAuthenticated &&
          (currentPath == AppRoutes.login ||
              currentPath == AppRoutes.register)) {
        if (resolvedRole != null) {
          return AppRoutes.home;
        } else {
          // Unknown or missing role: fail closed!
          return AppRoutes.login;
        }
      }

      // 3. Fail closed on unknown or missing roles:
      // If user is authenticated but has an unknown/missing role, deny access to all protected routes
      if (!isPublicRoute && resolvedRole == null) {
        return AppRoutes.login;
      }

      // 4. Role-based Route Protection:
      // A. Candidate (UserRole.user) only actions:
      // Recruiters and Admins MUST NOT access applicant-only actions (apply job, applicant history, create CV)
      if (isApplyRoute || isApplicationRoute || isCreateCvRoute) {
        if (resolvedRole != UserRole.user) {
          if (isApplyRoute) {
            // Redirect back to job detail if trying to apply
            final jobId = state.pathParameters['id'];
            return jobId != null ? '/jobs/$jobId' : AppRoutes.jobs;
          }
          return AppRoutes.home;
        }
      }

      // B. Recruiter (UserRole.recruiter) only routes:
      // Candidates and Admins cannot access recruiter-only routes
      if (isRecruiterRoute) {
        if (resolvedRole != UserRole.recruiter) {
          return AppRoutes.home;
        }
      }

      return null; // Allowed
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
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.createCv,
        name: 'create-cv',
        builder: (context, state) => const CreateCvScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.recruiterJobs,
        name: 'recruiter-jobs',
        builder: (context, state) => const JobListScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home (Candidate, Recruiter, Admin)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Search (Candidate, Recruiter, Admin)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                name: 'search',
                builder: (context, state) {
                  final query = state.uri.queryParameters['q'];
                  return SearchScreen(initialQuery: query);
                },
              ),
            ],
          ),
          // Branch 2: Applications (Candidate only)
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
          // Branch 3: Jobs (Recruiter bottom nav tab)
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
          // Branch 4: Profile (Candidate, Recruiter, Admin)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    parentNavigatorKey: _rootNavigatorKey,
                    path: 'detail',
                    name: 'profile-detail',
                    builder: (context, state) => const ProfileDetailScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
