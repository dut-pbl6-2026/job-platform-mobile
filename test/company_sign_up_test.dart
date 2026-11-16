import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_platform_mobile/core/constants/company_self_serve_strings.dart';
import 'package:job_platform_mobile/core/error/error_mapper.dart';
import 'package:job_platform_mobile/core/error/failures.dart';
import 'package:job_platform_mobile/features/auth/data/repositories/api_auth_repository.dart';
import 'package:job_platform_mobile/features/auth/presentation/company_sign_up_screen.dart';

/// Dio that answers each request from a queue. The last reply repeats.
class _ScriptedDio {
  _ScriptedDio(this._replies) {
    dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final reply = _replies.length > 1
              ? _replies.removeAt(0)
              : _replies.first;
          if (reply.statusCode >= 400) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: reply.statusCode,
                  data: reply.body,
                ),
              ),
            );
          } else {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: reply.statusCode,
                data: reply.body,
              ),
            );
          }
        },
      ),
    );
  }

  final List<_Reply> _replies;
  late final Dio dio;
  final List<RequestOptions> requests = [];
}

class _Reply {
  const _Reply(this.statusCode, [this.body = const {}]);
  final int statusCode;
  final Map<String, dynamic> body;
}

const _path = '/api/auth/register-company';

const _acceptedProblem = {
  'type': 'about:blank',
  'title': 'Work email required',
  'status': 422,
  'detail': 'A work email address is required to register a company.',
  'errorCode': 'WORK_EMAIL_REQUIRED',
};

Map<String, dynamic> _validBody(RequestOptions options) =>
    options.data as Map<String, dynamic>;

Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('company_signup_company_name')),
    'Acme Việt Nam',
  );
  await tester.enterText(
    find.byKey(const Key('company_signup_email')),
    'hr@acme.vn',
  );
  await tester.enterText(
    find.byKey(const Key('company_signup_full_name')),
    'Nguyễn An',
  );
  await tester.enterText(
    find.byKey(const Key('company_signup_password')),
    'SecureP@ss123',
  );
  await tester.enterText(
    find.byKey(const Key('company_signup_confirm_password')),
    'SecureP@ss123',
  );
  await tester.pump();
}

Future<void> _submit(WidgetTester tester) async {
  final submit = find.byKey(const Key('company_signup_submit'));
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

void main() {
  group('ApiAuthRepository.registerCompany (AUTH-01-10)', () {
    test('posts every field to the gateway route', () async {
      final server = _ScriptedDio([
        const _Reply(202, {'message': 'Check your email'}),
      ]);
      final repo = ApiAuthRepository(dio: server.dio);

      await repo.registerCompany(
        companyName: '  Acme Việt Nam ',
        taxCode: ' 0312345678 ',
        email: 'hr@acme.vn',
        password: 'SecureP@ss123',
        fullName: ' Nguyễn An ',
      );

      expect(server.requests, hasLength(1));
      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(request.path, _path);
      expect(request.data, {
        'companyName': 'Acme Việt Nam',
        'taxCode': '0312345678',
        'email': 'hr@acme.vn',
        'password': 'SecureP@ss123',
        'fullName': 'Nguyễn An',
      });
    });

    test('omits an empty tax code instead of sending a blank value', () async {
      final server = _ScriptedDio([const _Reply(202)]);
      final repo = ApiAuthRepository(dio: server.dio);

      await repo.registerCompany(
        companyName: 'Acme',
        taxCode: '   ',
        email: 'hr@acme.vn',
        password: 'SecureP@ss123',
        fullName: 'Nguyễn An',
      );

      expect(
        _validBody(server.requests.single).containsKey('taxCode'),
        isFalse,
      );
    });

    test('every 202 is the same success, whatever the body says', () async {
      // The server uses this same response for an existing email, a taken
      // company name or tax code, and a domain match. The client must not read
      // any of that from the body.
      final server = _ScriptedDio([
        const _Reply(202, {
          'message': 'Company name already exists',
          'companyId': 'should-not-be-used',
        }),
      ]);
      final repo = ApiAuthRepository(dio: server.dio);

      await expectLater(
        repo.registerCompany(
          companyName: 'Acme',
          email: 'hr@acme.vn',
          password: 'SecureP@ss123',
          fullName: 'Nguyễn An',
        ),
        completes,
      );
    });

    test('422 WORK_EMAIL_REQUIRED maps to the work-email failure', () async {
      final server = _ScriptedDio([const _Reply(422, _acceptedProblem)]);
      final repo = ApiAuthRepository(dio: server.dio);

      await expectLater(
        repo.registerCompany(
          companyName: 'Acme',
          email: 'someone@gmail.com',
          password: 'SecureP@ss123',
          fullName: 'Nguyễn An',
        ),
        throwsA(
          isA<AuthFailure>()
              .having((f) => f.code, 'code', AuthFailure.workEmailRequired)
              .having((f) => f.statusCode, 'statusCode', 422),
        ),
      );
    });

    test('503 is retryable and distinct from a work-email error', () async {
      final server = _ScriptedDio([
        const _Reply(503, {'title': 'Service unavailable'}),
      ]);
      final repo = ApiAuthRepository(dio: server.dio);

      await expectLater(
        repo.registerCompany(
          companyName: 'Acme',
          email: 'hr@acme.vn',
          password: 'SecureP@ss123',
          fullName: 'Nguyễn An',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.serviceUnavailable,
          ),
        ),
      );
    });

    test('a weak password fails before any request', () async {
      final server = _ScriptedDio([const _Reply(202)]);
      final repo = ApiAuthRepository(dio: server.dio);

      await expectLater(
        repo.registerCompany(
          companyName: 'Acme',
          email: 'hr@acme.vn',
          password: 'weakpass',
          fullName: 'Nguyễn An',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.weakPassword,
          ),
        ),
      );
      expect(server.requests, isEmpty);
    });

    test('the new failures have Vietnamese copy', () {
      expect(
        authFailureToMessage(
          const AuthFailure(code: AuthFailure.workEmailRequired),
        ),
        contains('email công ty'),
      );
      expect(
        authFailureToMessage(
          const AuthFailure(code: AuthFailure.serviceUnavailable),
        ),
        contains('thử lại'),
      );
    });
  });

  group('CompanySignUpScreen', () {
    testWidgets('validates every required field before calling the API', (
      tester,
    ) async {
      final server = _ScriptedDio([const _Reply(202)]);
      await tester.pumpWidget(
        MaterialApp(
          home: CompanySignUpScreen(
            authRepository: ApiAuthRepository(dio: server.dio),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _submit(tester);

      expect(
        find.text(CompanySignUpStrings.companyNameRequired),
        findsOneWidget,
      );
      expect(find.text(CompanySignUpStrings.emailRequired), findsOneWidget);
      expect(find.text(CompanySignUpStrings.fullNameRequired), findsOneWidget);
      expect(find.text(CompanySignUpStrings.passwordRequired), findsOneWidget);
      expect(find.text(CompanySignUpStrings.confirmRequired), findsOneWidget);
      expect(server.requests, isEmpty);
    });

    testWidgets('rejects a mismatched confirmation', (tester) async {
      final server = _ScriptedDio([const _Reply(202)]);
      await tester.pumpWidget(
        MaterialApp(
          home: CompanySignUpScreen(
            authRepository: ApiAuthRepository(dio: server.dio),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _fillValidForm(tester);
      await tester.enterText(
        find.byKey(const Key('company_signup_confirm_password')),
        'DifferentP@ss1',
      );
      await _submit(tester);

      expect(find.text(CompanySignUpStrings.confirmMismatch), findsOneWidget);
      expect(server.requests, isEmpty);
    });

    testWidgets('shows one message for every outcome, then goes to login', (
      tester,
    ) async {
      final server = _ScriptedDio([
        const _Reply(202, {'message': 'ok'}),
      ]);
      final router = GoRouter(
        initialLocation: '/register-company',
        routes: [
          GoRoute(
            path: '/register-company',
            builder: (context, state) => CompanySignUpScreen(
              authRepository: ApiAuthRepository(dio: server.dio),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Text('login-screen')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await _fillValidForm(tester);
      await _submit(tester);

      expect(find.text(CompanySignUpStrings.accepted), findsOneWidget);
      expect(find.textContaining('đã tồn tại'), findsNothing);
      expect(find.textContaining('đã được đăng ký'), findsNothing);
      expect(find.text('login-screen'), findsNothing);

      await tester.tap(
        find.byKey(const Key('company_signup_accepted_continue')),
      );
      await tester.pumpAndSettle();

      expect(find.text('login-screen'), findsOneWidget);
    });

    testWidgets('422 WORK_EMAIL_REQUIRED appears on the email field', (
      tester,
    ) async {
      final server = _ScriptedDio([const _Reply(422, _acceptedProblem)]);
      await tester.pumpWidget(
        MaterialApp(
          home: CompanySignUpScreen(
            authRepository: ApiAuthRepository(dio: server.dio),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _fillValidForm(tester);
      await _submit(tester);

      expect(find.text(CompanySignUpStrings.workEmailRequired), findsOneWidget);
      expect(find.text(CompanySignUpStrings.accepted), findsNothing);
      expect(find.text(CompanySignUpStrings.serviceUnavailable), findsNothing);
    });

    testWidgets('an unknown 422 is a generic failure, not an invite code', (
      tester,
    ) async {
      final server = _ScriptedDio([
        const _Reply(422, {
          'title': 'One or more validation errors occurred.',
          'status': 422,
          'errors': {
            'CompanyName': ['The company name is invalid.'],
          },
        }),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: CompanySignUpScreen(
            authRepository: ApiAuthRepository(dio: server.dio),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _fillValidForm(tester);
      await _submit(tester);

      expect(find.text(CompanySignUpStrings.failed), findsOneWidget);
      expect(find.textContaining('Mã mời'), findsNothing);
      expect(find.text(CompanySignUpStrings.accepted), findsNothing);
      // The form keeps its values so the user can correct the field.
      expect(find.byKey(const Key('company_signup_retry')), findsOneWidget);
    });

    testWidgets('a coded 422 that is not WORK_EMAIL_REQUIRED is generic', (
      tester,
    ) async {
      final server = _ScriptedDio([
        const _Reply(422, {'errorCode': 'TAX_CODE_INVALID'}),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: CompanySignUpScreen(
            authRepository: ApiAuthRepository(dio: server.dio),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _fillValidForm(tester);
      await _submit(tester);

      expect(find.text(CompanySignUpStrings.failed), findsOneWidget);
      expect(find.textContaining('Mã mời'), findsNothing);
    });

    testWidgets('every field label is its accessible name', (tester) async {
      final handle = tester.ensureSemantics();
      final server = _ScriptedDio([const _Reply(202)]);
      await tester.pumpWidget(
        MaterialApp(
          home: CompanySignUpScreen(
            authRepository: ApiAuthRepository(dio: server.dio),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen readers (and getByLabel-style finders) must hear the label, not
      // only the hint: the hint alone never says which field failed.
      expect(
        find.bySemanticsLabel(CompanySignUpStrings.companyNameLabel),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(CompanySignUpStrings.emailLabel),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(CompanySignUpStrings.passwordLabel),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('503 keeps the form and offers a retry that succeeds', (
      tester,
    ) async {
      final server = _ScriptedDio([
        const _Reply(503, {'title': 'Service unavailable'}),
        const _Reply(202, {'message': 'ok'}),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: CompanySignUpScreen(
            authRepository: ApiAuthRepository(dio: server.dio),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _fillValidForm(tester);
      await _submit(tester);

      expect(
        find.text(CompanySignUpStrings.serviceUnavailable),
        findsOneWidget,
      );
      expect(find.byKey(const Key('company_signup_retry')), findsOneWidget);
      expect(find.text(CompanySignUpStrings.accepted), findsNothing);

      final retry = find.byKey(const Key('company_signup_retry'));
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(server.requests, hasLength(2));
      expect(find.text(CompanySignUpStrings.accepted), findsOneWidget);
    });
  });
}
