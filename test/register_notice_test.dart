import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_platform_mobile/features/auth/data/repositories/api_auth_repository.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/auth/login_screen.dart';
import 'package:job_platform_mobile/features/auth/register_screen.dart';

/// Answers every request with 202, the registration contract.
Dio _acceptingDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 202,
          data: const {'message': 'ok'},
        ),
      ),
    ),
  );
  return dio;
}

Future<void> _fill(
  WidgetTester tester, {
  required UserRole role,
  required String email,
}) async {
  await tester.tap(find.byKey(Key('register_role_${role.name}')));
  await tester.pumpAndSettle();

  final fields = find.byType(TextFormField);
  expect(fields, findsNWidgets(role == UserRole.recruiter ? 5 : 4));

  await tester.enterText(fields.at(0), 'Nguyễn An');
  await tester.enterText(fields.at(1), email);
  await tester.enterText(fields.at(2), 'SecureP@ss123');
  await tester.enterText(fields.at(3), 'SecureP@ss123');
  if (role == UserRole.recruiter) {
    await tester.enterText(fields.at(4), 'ABCD-EFGH-JKLM');
  }
  await tester.pump();
}

Future<Object?> _submit(
  WidgetTester tester, {
  required UserRole role,
  required String email,
}) async {
  Object? loginExtra;
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(
          authRepository: ApiAuthRepository(dio: _acceptingDio()),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          loginExtra = state.extra;
          return const Scaffold(body: Text('login-screen'));
        },
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();

  await _fill(tester, role: role, email: email);

  final submit = find.byType(ElevatedButton);
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pumpAndSettle();

  return loginExtra;
}

void main() {
  testWidgets('an invited recruiter is told the account is ready, not to '
      'check email', (tester) async {
    final extra = await _submit(
      tester,
      role: UserRole.recruiter,
      email: 'new.hire@acme.vn',
    );

    expect(find.text(recruiterReadyNotice), findsOneWidget);
    expect(find.text(registrationPendingVerificationMessage), findsNothing);
    expect(find.textContaining('Check your email'), findsNothing);
    // auth-svc activates an invited recruiter at once and sends no mail, so the
    // navigation carries the notice and no address to verify.
    expect(extra, isA<Map>());
    expect((extra! as Map)['notice'], recruiterReadyNotice);
    expect((extra as Map)['email'], isNull);
    expect(find.text('login-screen'), findsOneWidget);
  });

  testWidgets('a candidate is still asked to verify, with the address', (
    tester,
  ) async {
    final extra = await _submit(
      tester,
      role: UserRole.user,
      email: 'candidate@example.com',
    );

    expect(find.text(registrationPendingVerificationMessage), findsOneWidget);
    expect(find.text(recruiterReadyNotice), findsNothing);
    expect(extra, 'candidate@example.com');
  });

  testWidgets('login shows a ready notice without a resend button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          authRepository: ApiAuthRepository(dio: _acceptingDio()),
          notice: recruiterReadyNotice,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(recruiterReadyNotice), findsOneWidget);
    expect(find.text(registrationPendingVerificationMessage), findsNothing);
    // A verified recruiter has nothing to resend.
    expect(find.textContaining('gửi lại'), findsNothing);
  });
}
