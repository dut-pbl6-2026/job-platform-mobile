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
