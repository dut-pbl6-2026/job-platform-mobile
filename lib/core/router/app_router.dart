import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../session/auth_session.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/applications/presentation/application_detail_screen.dart';
import '../../features/applications/presentation/application_history_screen.dart';
import '../../features/applications/presentation/apply_job_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/presentation/company_sign_up_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/company/presentation/company_profile_screen.dart';
import '../../features/company/presentation/join_request_status_screen.dart';
import '../../features/company/presentation/join_requests_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/main_navigation_screen.dart';
import '../../features/jobs/presentation/job_detail_screen.dart';
import '../../features/jobs/presentation/job_list_screen.dart';
import '../../features/jobs/presentation/search_screen.dart';
import '../../features/profile/presentation/profile_detail_screen.dart';
import '../../features/recruiter/domain/models/recruiter_models.dart';
import '../../features/recruiter/presentation/candidate_applications_screen.dart';
import '../../features/recruiter/presentation/invite_code_screen.dart';
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
  static const String companySignUp = '/register-company';
  static const String home = '/home';
  static const String jobs = '/jobs';
  static const String search = '/search';
  static const String jobDetail = '/jobs/:id';
  static const String applyJob = '/jobs/:id/apply';
  static const String applications = '/applications';
  static const String applicationDetail = '/applications/:id';
  static const String profile = '/profile';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';
  static const String recruiterDashboard = '/recruiter/dashboard';
  static const String recruiterJobs = '/recruiter/jobs';
  static const String recruiterPostJob = '/recruiter/jobs/create';
  static const String recruiterInviteCodes = '/recruiter/invite-codes';
  static const String recruiterJoinRequests = '/recruiter/join-requests';
  static const String recruiterCandidates = '/recruiter/candidates';
  static const String companyProfile = '/recruiter/company';

  /// Requester-side status of the signed-in account's join request.
  static const String myJoinRequest = '/my-join-request';

  /// Public routes that do not require authentication.
  static const List<String> publicRoutes = [
    splash,
    login,
    register,
    companySignUp,
    jobs,
    search,
    forgotPassword,
    resetPassword,
    verifyEmail,
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

      // /jobs and /jobs/:id are public browsing routes, but /jobs/:id/apply requires authentication and candidate role!
      final isPublicRoute =
          AppRoutes.publicRoutes.contains(currentPath) ||
          (currentPath.startsWith('/jobs') && !isApplyRoute);

      // 1. Unauthenticated users trying to access private/protected routes → redirect to login
      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      // 2. Authenticated users on login/register/company-sign-up:
      // If role is valid, redirect to home. If role is unknown or missing, fail closed
      // without creating a redirect loop when already on /login.
      if (isAuthenticated &&
          (currentPath == AppRoutes.login ||
              currentPath == AppRoutes.register ||
              currentPath == AppRoutes.companySignUp)) {
        if (resolvedRole != null) {
          return AppRoutes.home;
        } else {
          return currentPath == AppRoutes.login ? null : AppRoutes.login;
        }
      }

      // 3. Fail closed on unknown or missing roles:
      // If user is authenticated but has an unknown/missing role, deny access to all protected routes
      if (!isPublicRoute && resolvedRole == null) {
        return AppRoutes.login;
      }

      // 4. Role-based Route Protection:
      // A. Candidate (UserRole.user) only actions:
      // Recruiters and Admins MUST NOT access applicant-only actions (apply job, applicant history)
      if (isApplyRoute || isApplicationRoute) {
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
        builder: (context, state) {
          final extra = state.extra;
          // A candidate registration passes the address to verify; a recruiter
          // registration passes the "account ready" notice and no address.
          String? email;
          String? notice;
          if (extra is String) {
            email = extra;
          } else if (extra is Map) {
            email = extra['email']?.toString();
            notice = extra['notice']?.toString();
          }
          return LoginScreen(verificationEmail: email, notice: notice);
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.companySignUp,
        name: 'company-sign-up',
        builder: (context, state) => const CompanySignUpScreen(),
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
        path: AppRoutes.verifyEmail,
        name: 'verify-email',
        builder: (context, state) =>
            VerifyEmailScreen(token: state.uri.queryParameters['token']),
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
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileDetailScreen(),
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
        builder: (context, state) {
          final initialJob = state.extra is RecruiterJob
              ? state.extra as RecruiterJob
              : null;
          return PostJobScreen(initialJob: initialJob);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.recruiterInviteCodes,
        name: 'recruiter-invite-codes',
        builder: (context, state) => const InviteCodeScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.recruiterJoinRequests,
        name: 'recruiter-join-requests',
        builder: (context, state) => const JoinRequestsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.companyProfile,
        name: 'company-profile',
        builder: (context, state) => const CompanyProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.myJoinRequest,
        name: 'my-join-request',
        builder: (context, state) => const JoinRequestStatusScreen(),
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
        ],
      ),
    ],
  );
}
