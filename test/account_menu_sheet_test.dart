import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_platform_mobile/core/widgets/account_menu_sheet.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> loginAs(UserRole role) async {
    await AuthSession.instance.setSession(
      AuthResult(
        user: UserModel(
          id: 'user-1',
          name: 'Nguyễn Văn An',
          email: 'an@example.com',
          role: role,
          createdAt: DateTime.now(),
        ),
        token: 'test-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
  }

  Future<void> pumpHost(
    WidgetTester tester, {
    required void Function() onSignOut,
  }) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  key: const Key('open_account_menu'),
                  onPressed: () =>
                      AccountMenuSheet.show(context, onSignOut: onSignOut),
                  child: const Text('Mở tài khoản'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              const Scaffold(body: Text('Profile Destination')),
        ),
        GoRoute(
          path: '/applications',
          builder: (context, state) =>
              const Scaffold(body: Text('Applications Destination')),
        ),
        GoRoute(
          path: '/recruiter/company',
          builder: (context, state) =>
              const Scaffold(body: Text('Company Destination')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    );
    await tester.tap(find.byKey(const Key('open_account_menu')));
    await tester.pumpAndSettle();
  }

  testWidgets('candidate sees Profile, Applications and Sign out', (
    tester,
  ) async {
    await loginAs(UserRole.user);
    await pumpHost(tester, onSignOut: () {});

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('an@example.com'), findsOneWidget);
    expect(find.byKey(const Key('account_menu_profile')), findsOneWidget);
    expect(find.byKey(const Key('account_menu_applications')), findsOneWidget);
    expect(find.byKey(const Key('account_menu_company')), findsNothing);
    expect(find.byKey(const Key('account_menu_sign_out')), findsOneWidget);
  });

  testWidgets('recruiter sees Profile and Company but not Applications', (
    tester,
  ) async {
    await loginAs(UserRole.recruiter);
    await pumpHost(tester, onSignOut: () {});

    expect(find.byKey(const Key('account_menu_profile')), findsOneWidget);
    expect(find.byKey(const Key('account_menu_company')), findsOneWidget);
    expect(find.byKey(const Key('account_menu_applications')), findsNothing);
  });

  testWidgets('admin only sees Profile and Sign out (no Admin screen yet)', (
    tester,
  ) async {
    await loginAs(UserRole.admin);
    await pumpHost(tester, onSignOut: () {});

    expect(find.byKey(const Key('account_menu_profile')), findsOneWidget);
    expect(find.byKey(const Key('account_menu_applications')), findsNothing);
    expect(find.byKey(const Key('account_menu_company')), findsNothing);
    expect(find.byKey(const Key('account_menu_sign_out')), findsOneWidget);
  });

  testWidgets('Profile opens ProfileDetail route for a recruiter', (
    tester,
  ) async {
    await loginAs(UserRole.recruiter);
    await pumpHost(tester, onSignOut: () {});

    await tester.tap(find.byKey(const Key('account_menu_profile')));
    await tester.pumpAndSettle();

    expect(find.text('Profile Destination'), findsOneWidget);
  });

  testWidgets('Company opens the recruiter company route', (tester) async {
    await loginAs(UserRole.recruiter);
    await pumpHost(tester, onSignOut: () {});

    await tester.tap(find.byKey(const Key('account_menu_company')));
    await tester.pumpAndSettle();

    expect(find.text('Company Destination'), findsOneWidget);
  });

  testWidgets('Sign out closes the sheet and invokes the callback', (
    tester,
  ) async {
    await loginAs(UserRole.user);
    var signedOut = false;
    await pumpHost(tester, onSignOut: () => signedOut = true);

    await tester.tap(find.byKey(const Key('account_menu_sign_out')));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
    expect(find.byKey(const Key('account_menu_sign_out')), findsNothing);
  });
}
