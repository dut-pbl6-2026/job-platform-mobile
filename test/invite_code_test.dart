import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/error/error_mapper.dart';
import 'package:job_platform_mobile/core/error/failures.dart';
import 'package:job_platform_mobile/features/auth/data/repositories/api_auth_repository.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/recruiter/data/repositories/api_invite_code_repository.dart';

/// Dio that records every request and answers with [respond]. No network.
Dio _stubDio(
  List<RequestOptions> seen,
  Response<dynamic> Function(RequestOptions options) respond,
) {
  final dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        seen.add(options);
        final response = respond(options);
        if (response.statusCode != null && response.statusCode! >= 400) {
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

Response<dynamic> _reply(RequestOptions options, int status, [Object? data]) =>
    Response<dynamic>(requestOptions: options, statusCode: status, data: data);

void main() {
  group('recruiter registration sends an invite code (SRS AUTH-01-06)', () {
    test('Recruiter without a code fails before any request', () async {
      final seen = <RequestOptions>[];
      final repo = ApiAuthRepository(
        dio: _stubDio(seen, (o) => _reply(o, 202, {'message': 'ok'})),
      );

      await expectLater(
        repo.register(
          name: 'Recruiter',
          email: 'r@test.com',
          password: 'SecureP@ss123',
          role: UserRole.recruiter,
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.invalidInviteCode,
          ),
        ),
      );
      expect(seen, isEmpty);
    });

    test('code is normalised and sent, companyId is not', () async {
      final seen = <RequestOptions>[];
      final repo = ApiAuthRepository(
        dio: _stubDio(seen, (o) => _reply(o, 202, {'message': 'ok'})),
      );

      await repo.register(
        name: 'Recruiter',
        email: 'r@test.com',
        password: 'SecureP@ss123',
        role: UserRole.recruiter,
        inviteCode: 'abcd-efgh-jklm',
      );

      expect(seen, hasLength(1));
      final body = seen.single.data as Map<String, dynamic>;
      expect(body['inviteCode'], 'ABCDEFGHJKLM');
      expect(body.containsKey('companyId'), isFalse);
    });

    test('the code and the email it was issued to are sent together', () async {
      final seen = <RequestOptions>[];
      final repo = ApiAuthRepository(
        dio: _stubDio(seen, (o) => _reply(o, 202, {'message': 'ok'})),
      );

      await repo.register(
        name: 'Recruiter',
        email: 'New.Hire@Acme.vn',
        password: 'SecureP@ss123',
        role: UserRole.recruiter,
        inviteCode: 'ABCD-EFGH-JKLM',
        inviteEmail: 'new.hire@acme.vn',
      );

      final body = seen.single.data as Map<String, dynamic>;
      // job-svc checks and redeems the code against the registration email
      // (AUTH-01-15), so both values must reach `/api/auth/register`.
      expect(body['email'], 'New.Hire@Acme.vn');
      expect(body['inviteCode'], 'ABCDEFGHJKLM');
    });

    test('a different invite email fails before any request', () async {
      final seen = <RequestOptions>[];
      final repo = ApiAuthRepository(
        dio: _stubDio(seen, (o) => _reply(o, 202, {'message': 'ok'})),
      );

      await expectLater(
        repo.register(
          name: 'Recruiter',
          email: 'someone@acme.vn',
          password: 'SecureP@ss123',
          role: UserRole.recruiter,
          inviteCode: 'ABCD-EFGH-JKLM',
          inviteEmail: 'new.hire@acme.vn',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.invalidInviteCode,
          ),
        ),
      );
      expect(seen, isEmpty);
    });

    test('422 maps to invalid invite code, 503 to unavailable', () async {
      final invalid = ApiAuthRepository(
        dio: _stubDio(
          [],
          (o) => _reply(o, 422, {'errorCode': 'INVITE_CODE_INVALID'}),
        ),
      );
      await expectLater(
        invalid.register(
          name: 'Recruiter',
          email: 'r@test.com',
          password: 'SecureP@ss123',
          role: UserRole.recruiter,
          inviteCode: 'ABCDEFGHJKLM',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.invalidInviteCode,
          ),
        ),
      );

      final unavailable = ApiAuthRepository(
        dio: _stubDio([], (o) => _reply(o, 503)),
      );
      await expectLater(
        unavailable.register(
          name: 'Recruiter',
          email: 'r@test.com',
          password: 'SecureP@ss123',
          role: UserRole.recruiter,
          inviteCode: 'ABCDEFGHJKLM',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.inviteUnavailable,
          ),
        ),
      );
    });

    test('invite failures have Vietnamese copy', () {
      expect(
        authFailureToMessage(
          const AuthFailure(code: AuthFailure.invalidInviteCode),
        ).toLowerCase(),
        contains('mã mời'),
      );
      expect(
        authFailureToMessage(
          const AuthFailure(code: AuthFailure.inviteUnavailable),
        ).toLowerCase(),
        contains('mã mời'),
      );
    });
  });

  group('creator issues invite codes', () {
    test('posts the bound email and parses the one-time code', () async {
      final seen = <RequestOptions>[];
      final repo = ApiInviteCodeRepository(
        dio: _stubDio(
          seen,
          (o) => _reply(o, 201, {
            'id': '55555555-5555-5555-5555-555555555555',
            'code': 'ABCD-EFGH-JKLM',
            'email': 'new.hire@acme.vn',
            'expiresAt': '2099-01-07T00:00:00Z',
          }),
        ),
      );

      final issued = await repo.createInviteCode(
        companyId: 'company-1',
        email: ' new.hire@acme.vn ',
      );

      expect(seen.single.path, '/api/companies/company-1/invite-codes');
      expect(seen.single.method, 'POST');
      // AUTH-01-15: the code is bound to one address, sent with the request.
      expect(seen.single.data, {'email': 'new.hire@acme.vn'});
      expect(issued.code, 'ABCD-EFGH-JKLM');
      expect(issued.email, 'new.hire@acme.vn');
      expect(issued.expiresAt.isAfter(DateTime(2099)), isTrue);
    });

    test('403 explains that only the creator can issue', () async {
      final repo = ApiInviteCodeRepository(
        dio: _stubDio([], (o) => _reply(o, 403, {'message': 'x'})),
      );

      await expectLater(
        repo.createInviteCode(
          companyId: 'company-1',
          email: 'new.hire@acme.vn',
        ),
        throwsA(
          isA<InviteCodeException>().having(
            (e) => e.message,
            'message',
            contains('người tạo công ty'),
          ),
        ),
      );
    });

    test(
      '422 INVITE_EMAIL_INVALID is a field message, not a network error',
      () async {
        final repo = ApiInviteCodeRepository(
          dio: _stubDio(
            [],
            (o) => _reply(o, 422, {'errorCode': 'INVITE_EMAIL_INVALID'}),
          ),
        );

        await expectLater(
          repo.createInviteCode(companyId: 'company-1', email: 'nope'),
          throwsA(
            isA<InviteCodeException>().having(
              (e) => e.message,
              'message',
              contains('Email'),
            ),
          ),
        );
      },
    );

    test('a transport failure has retry copy', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          ),
        ),
      );
      final repo = ApiInviteCodeRepository(dio: dio);

      await expectLater(
        repo.createInviteCode(
          companyId: 'company-1',
          email: 'new.hire@acme.vn',
        ),
        throwsA(
          isA<InviteCodeException>().having(
            (e) => e.message,
            'message',
            contains('thử lại'),
          ),
        ),
      );
    });
  });
}
