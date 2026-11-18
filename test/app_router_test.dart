import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_platform_mobile/core/router/app_router.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AuthSession.instance.clearSession();
  });

  tearDown(() {
    AuthSession.instance.clearSession();
  });

  group('AppRouter Route Guard Tests (Issue 4.2 / SEC-08)', () {
    test('Personal Figma routes require authentication', () {
      for (final path in [AppRoutes.profile]) {
        final redirect = AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState(path),
        );
        expect(redirect, AppRoutes.login, reason: path);
      }
    });

    test('Candidate cannot access recruiter screens', () {
      AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'candidate',
            name: 'Candidate',
            email: 'c@example.com',
            role: UserRole.user,
            createdAt: DateTime.now(),
          ),
          token: 'jwt-token',
          refreshToken: 'refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      for (final path in [
        AppRoutes.recruiterDashboard,
        AppRoutes.recruiterJobs,
        AppRoutes.recruiterPostJob,
        AppRoutes.recruiterCandidates,
        AppRoutes.companyProfile,
      ]) {
        expect(
          AppRouter.router.configuration.topRedirect(
            TestBuildContext(),
            TestGoRouterState(path),
          ),
          AppRoutes.home,
        );
      }
    });

    test('Recruiter can open the profile and company routes', () {
      AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'recruiter',
            name: 'Recruiter',
            email: 'r@example.com',
            role: UserRole.recruiter,
            createdAt: DateTime.now(),
          ),
          token: 'jwt-token',
          refreshToken: 'refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      for (final path in [AppRoutes.profile, AppRoutes.companyProfile]) {
        expect(
          AppRouter.router.configuration.topRedirect(
            TestBuildContext(),
            TestGoRouterState(path),
          ),
          isNull,
          reason: path,
        );
      }
    });

    test(
      'Unauthenticated user navigating to /jobs/1/apply is redirected to login',
      () {
        final redirectPath = AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState('/jobs/job-1/apply'),
        );
        expect(redirectPath, equals(AppRoutes.login));
      },
    );

    test('Unauthenticated user can access public /jobs and /jobs/job-1', () {
      final redirectJobs = AppRouter.router.configuration.topRedirect(
        TestBuildContext(),
        TestGoRouterState('/jobs'),
      );
      expect(redirectJobs, isNull);

      final redirectJobDetail = AppRouter.router.configuration.topRedirect(
        TestBuildContext(),
        TestGoRouterState('/jobs/job-1'),
      );
      expect(redirectJobDetail, isNull);
    });

    test('Authenticated user is allowed on /jobs/job-1/apply', () {
      AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'user-1',
            name: 'Candidate',
            email: 'candidate@example.com',
            role: UserRole.user,
            createdAt: DateTime.now(),
          ),
          token: 'jwt-token',
          refreshToken: 'refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      final redirectApply = AppRouter.router.configuration.topRedirect(
        TestBuildContext(),
        TestGoRouterState('/jobs/job-1/apply'),
      );
      expect(redirectApply, isNull);
    });

    test('Authenticated user on /login is redirected to /home', () {
      AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'user-1',
            name: 'Candidate',
            email: 'candidate@example.com',
            role: UserRole.user,
            createdAt: DateTime.now(),
          ),
          token: 'jwt-token',
          refreshToken: 'refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      final redirectLogin = AppRouter.router.configuration.topRedirect(
        TestBuildContext(),
        TestGoRouterState('/login'),
      );
      expect(redirectLogin, equals(AppRoutes.home));
    });

    test('Verification link is reachable while signed out', () {
      final redirect = AppRouter.router.configuration.topRedirect(
        TestBuildContext(),
        TestGoRouterState(AppRoutes.verifyEmail),
      );
      expect(redirect, isNull);
    });

    test('Company sign-up is public, but the join-request status is not', () {
      expect(
        AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState(AppRoutes.companySignUp),
        ),
        isNull,
      );
      expect(
        AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState(AppRoutes.myJoinRequest),
        ),
        AppRoutes.login,
      );
    });

    test('Join-request admin list is recruiter-only', () {
      AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'candidate',
            name: 'Candidate',
            email: 'c@example.com',
            role: UserRole.user,
            createdAt: DateTime.now(),
          ),
          token: 'jwt-token',
          refreshToken: 'refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      expect(
        AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState(AppRoutes.recruiterJoinRequests),
        ),
        AppRoutes.home,
      );
    });

    test(
      'normalizeDeepLinkUri maps job:// links and rejects unknown hosts',
      () {
        expect(
          AppRouter.normalizeDeepLinkUri(
            Uri.parse('job://verify-email?token=abc-123'),
          ),
          '/verify-email?token=abc-123',
        );
        expect(
          AppRouter.normalizeDeepLinkUri(
            Uri.parse('job://reset-password?token=xyz'),
          ),
          '/reset-password?token=xyz',
        );
        expect(
          AppRouter.normalizeDeepLinkUri(Uri.parse('job://jobs/job-42')),
          '/jobs/job-42',
        );
        expect(
          AppRouter.normalizeDeepLinkUri(
            Uri.parse('job://applications/app-99'),
          ),
          '/applications/app-99',
        );
        expect(
          AppRouter.normalizeDeepLinkUri(Uri.parse('job://search?q=flutter')),
          '/search?q=flutter',
        );
        expect(
          AppRouter.normalizeDeepLinkUri(Uri.parse('job://home')),
          AppRoutes.home,
        );
        expect(
          AppRouter.normalizeDeepLinkUri(
            Uri.parse('https://evil.example/jobs'),
          ),
          isNull,
        );
        expect(
          AppRouter.normalizeDeepLinkUri(Uri.parse('job://unknown/path')),
          isNull,
        );
        expect(
          AppRouter.router.configuration.topRedirect(
            TestBuildContext(),
            TestGoRouterState('job://jobs/job-42'),
          ),
          '/jobs/job-42',
        );
      },
    );
  });
}

class TestBuildContext extends Fake implements BuildContext {}

class TestGoRouterState extends Fake implements GoRouterState {
  @override
  final String matchedLocation;

  TestGoRouterState(this.matchedLocation);

  @override
  Uri get uri => Uri.parse(matchedLocation);
}
