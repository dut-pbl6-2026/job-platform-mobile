import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/constants/company_self_serve_strings.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/recruiter/data/repositories/api_invite_code_repository.dart';
import 'package:job_platform_mobile/features/recruiter/presentation/invite_code_screen.dart';

class _Reply {
  const _Reply(this.statusCode, [this.body = const {}]);
  final int statusCode;
  final Map<String, dynamic> body;
}

/// Answers each request from a queue; the last reply repeats.
Dio _scriptedDio(List<_Reply> replies) {
  final dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final reply = replies.length > 1 ? replies.removeAt(0) : replies.first;
        final response = Response<dynamic>(
          requestOptions: options,
          statusCode: reply.statusCode,
          data: reply.body,
        );
        if (reply.statusCode >= 400) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: response,
            ),
          );
        } else {
          handler.resolve(response);
        }
      },
    ),
  );
  return dio;
}

void main() {
  setUp(() async {
    await AuthSession.instance.setSession(
      AuthResult(
        token: 'token',
        refreshToken: 'refresh',
        user: UserModel(
          id: 'admin-1',
          name: 'Nguyễn An',
          email: 'admin@acme.vn',
          role: UserRole.recruiter,
          companyId: 'company-1',
          createdAt: DateTime(2026),
        ),
        expiresAt: DateTime(2030),
      ),
    );
  });

  tearDown(() async {
    await AuthSession.instance.clearSession();
  });

  testWidgets('a failed reissue keeps the code that was already issued', (
    tester,
  ) async {
    final dio = _scriptedDio([
      const _Reply(201, {
        'id': 'invite-1',
        'code': 'ABCD-EFGH-JKLM',
        'email': 'first@acme.vn',
        'expiresAt': '2099-01-07T00:00:00Z',
      }),
      const _Reply(422, {'errorCode': 'INVITE_EMAIL_INVALID'}),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: InviteCodeScreen(repository: ApiInviteCodeRepository(dio: dio)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('invite_code_email')),
      'first@acme.vn',
    );
    await tester.tap(find.byKey(const Key('invite_code_submit')));
    await tester.pumpAndSettle();

    expect(find.text('ABCD-EFGH-JKLM'), findsOneWidget);

    // A second issue fails. The first code was shown once and cannot be
    // recovered, so it must stay on screen with the error above it.
    await tester.enterText(
      find.byKey(const Key('invite_code_email')),
      'someone@acme.vn',
    );
    await tester.tap(find.byKey(const Key('invite_code_submit')));
    await tester.pumpAndSettle();

    expect(find.text('ABCD-EFGH-JKLM'), findsOneWidget);
    expect(find.text(InviteCodeStrings.emailRejected), findsOneWidget);
    expect(find.text(InviteCodeStrings.showOnce), findsOneWidget);
  });
}
