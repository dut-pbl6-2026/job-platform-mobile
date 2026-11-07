import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../session/auth_session.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/ai_copilot/presentation/ai_copilot_screen.dart';
import '../../features/ai_copilot/presentation/resume_scoring_screen.dart';
import '../../features/applications/presentation/application_detail_screen.dart';
import '../../features/applications/presentation/application_history_screen.dart';
import '../../features/applications/presentation/apply_job_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/connections/presentation/connections_screen.dart';
import '../../features/cv/presentation/create_cv_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/main_navigation_screen.dart';
import '../../features/jobs/presentation/job_detail_screen.dart';
import '../../features/jobs/presentation/job_list_screen.dart';
import '../../features/jobs/presentation/saved_jobs_screen.dart';
import '../../features/jobs/presentation/search_screen.dart';
import '../../features/notifications/presentation/notification_screen.dart';
import '../../features/profile/presentation/profile_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/recruiter/presentation/candidate_applications_screen.dart';
import '../../features/recruiter/presentation/post_job_screen.dart';
import '../../features/recruiter/presentation/recruiter_dashboard_screen.dart';
import '../../features/recruiter/presentation/recruiter_jobs_screen.dart';
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
  static const String connections = '/connections';
  static const String savedJobs = '/saved-jobs';
  static const String aiCopilot = '/ai-copilot';
  static const String resumeScoring = '/resume-scoring';
  static const String recruiterDashboard = '/recruiter/dashboard';
  static const String recruiterJobs = '/recruiter/jobs';
  static const String recruiterPostJob = '/recruiter/jobs/create';
  static const String recruiterCandidates = '/recruiter/candidates';

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
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'];
          return SearchScreen(initialQuery: query);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.savedJobs,
        name: 'saved-jobs',
        builder: (context, state) => const SavedJobsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.aiCopilot,
        name: 'ai-copilot',
        builder: (context, state) => const AiCopilotScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.resumeScoring,
        name: 'resume-scoring',
        builder: (context, state) => ResumeScoringScreen(
          jobId: state.uri.queryParameters['jobId'],
          targetJobTitle: state.uri.queryParameters['title'],
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.recruiterDashboard,
        name: 'recruiter-dashboard',
        builder: (context, state) => const RecruiterDashboardScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.recruiterJobs,
        name: 'recruiter-jobs',
        builder: (context, state) => const RecruiterJobsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.recruiterPostJob,
        name: 'recruiter-post-job',
        builder: (context, state) => const PostJobScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.recruiterCandidates,
        name: 'recruiter-candidates',
        builder: (context, state) {
          final queryJobId = state.uri.queryParameters['jobId'];
          final extraJobId = state.extra is String
              ? state.extra as String
              : (state.extra is Map
                    ? (state.extra as Map)['jobId']?.toString()
                    : null);
          final jobId = queryJobId ?? extraJobId;
          return CandidateApplicationsScreen(jobId: jobId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
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
      StatefulShellRoute(
        navigatorContainerBuilder: (context, navigationShell, children) {
          return MainNavigationScreen(
            navigationShell: navigationShell,
            children: children,
          );
        },
        builder: (context, state, navigationShell) => navigationShell,
        branches: [
          // Branch 0: Trang chủ (#2073:870)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Việc làm (#2073:876)
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
          // Branch 2: Tạo CV (#2073:879)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.createCv,
                name: 'create-cv',
                builder: (context, state) => const CreateCvScreen(),
              ),
            ],
          ),
          // Branch 3: NTD kết nối (#2073:885)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.connections,
                name: 'connections',
                builder: (context, state) => const ConnectionsScreen(),
              ),
            ],
          ),
          // Branch 4: Hồ sơ (#2073:888)
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
