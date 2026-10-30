import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_platform_mobile/core/router/app_router.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/home/main_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String createTestJwt(String role) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final payload = base64Url.encode(
    utf8.encode('{"role":"$role","sub":"user-123"}'),
  );
  return '$header.$payload.testSignature';
}

Finder findNavTab(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    await AuthSession.instance.clearSession();
  });

  tearDown(() async {
    await AuthSession.instance.clearSession();
  });

  group('Role-Based Navigation & Route Guard Tests (MOB-01-07, AUTH-01-03)', () {
    // 1. User sees the correct navigation tabs
    testWidgets(
      '1. Candidate / User sees Home, Search, Applications, Profile tabs',
      (tester) async {
        await AuthSession.instance.setSession(
          AuthResult(
            user: UserModel(
              id: 'candidate-1',
              name: 'Nguyễn Ứng Viên',
              email: 'candidate@test.com',
              role: UserRole.user,
              createdAt: DateTime.now(),
            ),
            token: createTestJwt('User'),
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        final destinations = MainNavigationScreen.getDestinationsForRole(
          UserRole.user,
        );
        expect(destinations.length, equals(4));
        expect(destinations[0].label, equals('Trang chủ'));
        expect(destinations[1].label, equals('Tìm kiếm'));
        expect(destinations[2].label, equals('Ứng tuyển'));
        expect(destinations[3].label, equals('Hồ sơ'));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainNavigationScreen(body: SizedBox.shrink()),
          ),
        );
        await tester.pump();

        expect(findNavTab('Trang chủ'), findsOneWidget);
        expect(findNavTab('Tìm kiếm'), findsOneWidget);
        expect(findNavTab('Ứng tuyển'), findsOneWidget);
        expect(findNavTab('Hồ sơ'), findsOneWidget);
        // Recruiter jobs tab must not be present
        expect(findNavTab('Tin tuyển dụng'), findsNothing);
      },
    );

    // 2. Recruiter sees the Jobs tab
    testWidgets('2. Recruiter sees Home, Search, Jobs, Profile tabs', (
      tester,
    ) async {
      await AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'recruiter-1',
            name: 'Trần Tuyển Dụng',
            email: 'recruiter@company.com',
            role: UserRole.recruiter,
            createdAt: DateTime.now(),
          ),
          token: createTestJwt('Recruiter'),
          refreshToken: 'refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      final destinations = MainNavigationScreen.getDestinationsForRole(
        UserRole.recruiter,
      );
      expect(destinations.length, equals(4));
      expect(destinations[0].label, equals('Trang chủ'));
      expect(destinations[1].label, equals('Tìm kiếm'));
      expect(destinations[2].label, equals('Tin tuyển dụng'));
      expect(destinations[3].label, equals('Hồ sơ'));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(body: SizedBox.shrink()),
        ),
      );
      await tester.pump();

      expect(findNavTab('Trang chủ'), findsOneWidget);
      expect(findNavTab('Tìm kiếm'), findsOneWidget);
      expect(findNavTab('Tin tuyển dụng'), findsOneWidget);
      expect(findNavTab('Hồ sơ'), findsOneWidget);
      // Candidate application history tab must not be present
      expect(findNavTab('Ứng tuyển'), findsNothing);
    });

    // 3. Admin only sees supported Admin navigation
    testWidgets(
      '3. Admin only sees supported Admin navigation (Home, Search, Profile)',
      (tester) async {
        await AuthSession.instance.setSession(
          AuthResult(
            user: UserModel(
              id: 'admin-1',
              name: 'Quản Trị Viên',
              email: 'admin@system.com',
              role: UserRole.admin,
              createdAt: DateTime.now(),
            ),
            token: createTestJwt('Admin'),
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        final destinations = MainNavigationScreen.getDestinationsForRole(
          UserRole.admin,
        );
        expect(destinations.length, equals(3));
        expect(destinations[0].label, equals('Trang chủ'));
        expect(destinations[1].label, equals('Tìm kiếm'));
        expect(destinations[2].label, equals('Hồ sơ'));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainNavigationScreen(body: SizedBox.shrink()),
          ),
        );
        await tester.pump();

        expect(findNavTab('Trang chủ'), findsOneWidget);
        expect(findNavTab('Tìm kiếm'), findsOneWidget);
        expect(findNavTab('Hồ sơ'), findsOneWidget);
        // Unsupported tabs must not be exposed
        expect(findNavTab('Ứng tuyển'), findsNothing);
        expect(findNavTab('Tin tuyển dụng'), findsNothing);
      },
    );

    // 4. User cannot access Recruiter-only routes
    test(
      '4. Candidate cannot access Recruiter-only routes (/recruiter/jobs)',
      () async {
        await AuthSession.instance.setSession(
          AuthResult(
            user: UserModel(
              id: 'user-1',
              name: 'Candidate',
              email: 'candidate@test.com',
              role: UserRole.user,
              createdAt: DateTime.now(),
            ),
            token: createTestJwt('User'),
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        final redirect = AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState('/recruiter/jobs'),
        );
        expect(redirect, equals(AppRoutes.home));
      },
    );

    // 5. Recruiter cannot access User-only actions
    test(
      '5. Recruiter cannot access User-only actions (/jobs/:id/apply, /applications, /create-cv)',
      () async {
        await AuthSession.instance.setSession(
          AuthResult(
            user: UserModel(
              id: 'recruiter-1',
              name: 'Recruiter',
              email: 'recruiter@test.com',
              role: UserRole.recruiter,
              createdAt: DateTime.now(),
            ),
            token: createTestJwt('Recruiter'),
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        // Apply route redirected to job details
        final redirectApply = AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState('/jobs/job-100/apply', params: {'id': 'job-100'}),
        );
        expect(redirectApply, equals('/jobs/job-100'));

        // Applications route redirected to home
        final redirectApps = AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState('/applications'),
        );
        expect(redirectApps, equals(AppRoutes.home));

        // Create CV route redirected to home
        final redirectCreateCv = AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState('/create-cv'),
        );
        expect(redirectCreateCv, equals(AppRoutes.home));
      },
    );

    // 6. Unauthenticated users are redirected appropriately
    test(
      '6. Unauthenticated users are redirected to login for protected routes',
      () {
        expect(
          AppRouter.router.configuration.topRedirect(
            TestBuildContext(),
            TestGoRouterState('/home'),
          ),
          equals(AppRoutes.login),
        );
        expect(
          AppRouter.router.configuration.topRedirect(
            TestBuildContext(),
            TestGoRouterState('/applications'),
          ),
          equals(AppRoutes.login),
        );
        expect(
          AppRouter.router.configuration.topRedirect(
            TestBuildContext(),
            TestGoRouterState('/profile'),
          ),
          equals(AppRoutes.login),
        );
        expect(
          AppRouter.router.configuration.topRedirect(
            TestBuildContext(),
            TestGoRouterState('/jobs/job-1/apply'),
          ),
          equals(AppRoutes.login),
        );
        expect(
          AppRouter.router.configuration.topRedirect(
            TestBuildContext(),
            TestGoRouterState('/recruiter/jobs'),
          ),
          equals(AppRoutes.login),
        );

        // Public routes are permitted without redirection
        expect(
          AppRouter.router.configuration.topRedirect(
            TestBuildContext(),
            TestGoRouterState('/jobs'),
          ),
          isNull,
        );
        expect(
          AppRouter.router.configuration.topRedirect(
            TestBuildContext(),
            TestGoRouterState('/search'),
          ),
          isNull,
        );
        expect(
          AppRouter.router.configuration.topRedirect(
            TestBuildContext(),
            TestGoRouterState('/jobs/job-1'),
          ),
          isNull,
        );
      },
    );

    // 7. Unknown or missing roles are denied by default
    test(
      '7. Unknown or missing roles fail closed and are denied by default',
      () async {
        // Authenticated with token but role is unknown
        await AuthSession.instance.setSession(
          AuthResult(
            user: UserModel(
              id: 'unknown-1',
              name: 'Mystery User',
              email: 'unknown@test.com',
              role: null,
              createdAt: DateTime.now(),
            ),
            token: createTestJwt('UnknownRole'),
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        expect(AuthSession.instance.resolvedRole, isNull);
        expect(AuthSession.instance.hasValidRole, isFalse);

        // Denied access to protected routes
        final redirectHome = AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState('/home'),
        );
        expect(redirectHome, equals(AppRoutes.login));

        final redirectApps = AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState('/applications'),
        );
        expect(redirectApps, equals(AppRoutes.login));

        // When on login, should not be forwarded to home
        final redirectLogin = AppRouter.router.configuration.topRedirect(
          TestBuildContext(),
          TestGoRouterState('/login'),
        );
        expect(redirectLogin, equals(AppRoutes.login));
      },
    );

    // 8. Logout clears protected navigation state
    testWidgets('8. Logout clears protected navigation state', (tester) async {
      await AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'candidate-1',
            name: 'Candidate',
            email: 'candidate@test.com',
            role: UserRole.user,
            createdAt: DateTime.now(),
          ),
          token: createTestJwt('User'),
          refreshToken: 'refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(body: SizedBox.shrink()),
        ),
      );
      await tester.pump();
      expect(find.byType(NavigationBar), findsOneWidget);

      // Perform logout
      await AuthSession.instance.clearSession();
      await tester.pump();

      // Navigation destinations should be empty and NavigationBar removed
      expect(find.byType(NavigationBar), findsNothing);
      expect(AuthSession.instance.isAuthenticated, isFalse);
      expect(AuthSession.instance.resolvedRole, isNull);
    });

    // 9. Session restoration loads the correct navigation
    test(
      '9. Session restoration resolves authoritative role from stored session',
      () async {
        // Simulating session data with Recruiter JWT
        final authResult = AuthResult(
          user: UserModel(
            id: 'recruiter-99',
            name: 'Restored Recruiter',
            email: 'recruiter99@company.com',
            role: UserRole.recruiter,
            createdAt: DateTime.now(),
          ),
          token: createTestJwt('Recruiter'),
          refreshToken: 'refresh-99',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        await AuthSession.instance.setSession(authResult);

        expect(AuthSession.instance.isAuthenticated, isTrue);
        expect(AuthSession.instance.resolvedRole, equals(UserRole.recruiter));
        expect(AuthSession.instance.isRecruiter, isTrue);

        final destinations = MainNavigationScreen.getDestinationsForRole(
          AuthSession.instance.resolvedRole,
        );
        expect(
          destinations.map((d) => d.label).toList(),
          equals(['Trang chủ', 'Tìm kiếm', 'Tin tuyển dụng', 'Hồ sơ']),
        );
      },
    );

    // 10. Navigation changes correctly after login
    testWidgets('10. Navigation updates dynamically upon login state change', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(body: SizedBox.shrink()),
        ),
      );
      await tester.pump();

      // Initially unauthenticated: no nav bar
      expect(find.byType(NavigationBar), findsNothing);

      // Login as Candidate
      await AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'candidate-1',
            name: 'Candidate',
            email: 'candidate@test.com',
            role: UserRole.user,
            createdAt: DateTime.now(),
          ),
          token: createTestJwt('User'),
          refreshToken: 'refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(findNavTab('Ứng tuyển'), findsOneWidget);
      expect(findNavTab('Tin tuyển dụng'), findsNothing);

      // Switch session to Recruiter
      await AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'recruiter-1',
            name: 'Recruiter',
            email: 'recruiter@test.com',
            role: UserRole.recruiter,
            createdAt: DateTime.now(),
          ),
          token: createTestJwt('Recruiter'),
          refreshToken: 'refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      await tester.pump();

      expect(findNavTab('Tin tuyển dụng'), findsOneWidget);
      expect(findNavTab('Ứng tuyển'), findsNothing);
    });

    // 11. Security: Verified JWT token role claim takes precedence over client UserModel
    test(
      '11. Authoritative JWT token role takes precedence over manipulated UserModel role',
      () async {
        // Attacker changes UserModel in memory to 'Admin', but backend JWT token was issued for 'User'
        await AuthSession.instance.setSession(
          AuthResult(
            user: UserModel(
              id: 'user-attacker',
              name: 'Attacker',
              email: 'attacker@test.com',
              role: UserRole.admin, // Manipulated on client
              createdAt: DateTime.now(),
            ),
            token: createTestJwt('User'), // Genuine backend-issued token claim
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        // Authoritative role resolution must yield User from JWT, not Admin!
        expect(AuthSession.instance.resolvedRole, equals(UserRole.user));
        expect(AuthSession.instance.isAdmin, isFalse);
        expect(AuthSession.instance.isUser, isTrue);
      },
    );
  });
}

class TestBuildContext extends Fake implements BuildContext {}

class TestGoRouterState extends Fake implements GoRouterState {
  @override
  final String matchedLocation;

  @override
  final Map<String, String> pathParameters;

  TestGoRouterState(this.matchedLocation, {Map<String, String>? params})
    : pathParameters = params ?? {};

  @override
  Uri get uri => Uri.parse(matchedLocation);
}
