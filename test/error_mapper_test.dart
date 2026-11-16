import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/error/error_mapper.dart';
import 'package:job_platform_mobile/core/error/failures.dart';

DioException _response(int status, Map<String, dynamic> body) {
  final options = RequestOptions(path: '/api/auth/login');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: body,
    ),
  );
}

void main() {
  group('mapDioToFailure status and errorCode mapping', () {
    test('an unknown status keeps its status but no server copy', () {
      final failure = mapDioToFailure(
        _response(500, {
          'title': 'An error occurred',
          'detail': 'Npgsql.PostgresException: relation "users" does not exist',
          'traceId': '00-6f1e-00',
        }),
      );

      expect(failure.code, AuthFailure.unknown);
      expect(failure.statusCode, 500);
      final message = authFailureToMessage(failure);
      expect(message, genericFailureMessage);
      // The ProblemDetails body is kept for logs only, never shown.
      expect(message, isNot(contains('Npgsql')));
      expect(message, isNot(contains('00-6f1e')));
    });

    test('a 422 without an errorCode is a validation failure', () {
      final failure = mapDioToFailure(
        _response(422, {'title': 'One or more validation errors occurred.'}),
      );

      expect(failure.code, AuthFailure.requestInvalid);
    });

    test('a 422 with an unknown errorCode is not an invite-code error', () {
      final failure = mapDioToFailure(
        _response(422, {'errorCode': 'SOMETHING_NEW'}),
      );

      expect(failure.code, AuthFailure.requestInvalid);
      expect(authFailureToMessage(failure), isNot(contains('Mã mời')));
    });

    test('the known 422 codes keep their own copy', () {
      expect(
        mapDioToFailure(
          _response(422, {'errorCode': 'WORK_EMAIL_REQUIRED'}),
        ).code,
        AuthFailure.workEmailRequired,
      );
      expect(
        mapDioToFailure(
          _response(422, {'errorCode': 'VERIFICATION_TOKEN_INVALID'}),
        ).code,
        AuthFailure.verificationTokenInvalid,
      );
      expect(
        mapDioToFailure(
          _response(422, {'errorCode': 'INVITE_EMAIL_INVALID'}),
        ).code,
        AuthFailure.invalidInviteCode,
      );
    });

    test('401 splits on the server code, not on the raw text alone', () {
      expect(
        mapDioToFailure(_response(401, {'detail': 'Token expired'})).code,
        AuthFailure.tokenExpired,
      );
      expect(
        mapDioToFailure(_response(401, {'detail': 'Token revoked'})).code,
        AuthFailure.tokenRevoked,
      );
      expect(
        mapDioToFailure(_response(401, {'detail': 'Invalid credentials'})).code,
        AuthFailure.invalidCredentials,
      );
    });
  });

  group('user-facing copy', () {
    test('an unmatched code uses the caller fallback', () {
      const failure = AuthFailure(
        code: 'brand_new_code',
        rawMessage: 'DioException [bad response]: /api/internal',
      );

      expect(authFailureToMessage(failure), genericFailureMessage);
      expect(
        authFailureToMessage(failure, fallback: 'Không đăng nhập được.'),
        'Không đăng nhập được.',
      );
      expect(authFailureToMessage(failure), isNot(contains('DioException')));
    });

    test('failureMessage never stringifies the exception', () {
      expect(
        failureMessage(
          TypeError(),
          fallback: 'Đã xảy ra lỗi, vui lòng thử lại.',
        ),
        'Đã xảy ra lỗi, vui lòng thử lại.',
      );
      expect(
        failureMessage(
          const AuthFailure(code: AuthFailure.rateLimited),
          fallback: 'unused',
        ),
        rateLimitedMessage,
      );
    });

    test('login 401 copy is Vietnamese', () {
      expect(
        authFailureToMessage(
          const AuthFailure(code: AuthFailure.invalidCredentials),
        ),
        loginCredentialsOrVerifyMessage,
      );
      expect(
        loginCredentialsOrVerifyMessage,
        matches(
          RegExp(
            r'[àáâãèéêìíòóôõùúýăđĩũơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ]',
          ),
        ),
      );
    });
  });
}
