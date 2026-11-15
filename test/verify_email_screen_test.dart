import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/error/error_mapper.dart';
import 'package:job_platform_mobile/features/auth/data/repositories/api_auth_repository.dart';
import 'package:job_platform_mobile/features/auth/presentation/verify_email_screen.dart';

/// One scripted answer from the fake server: an HTTP status with a JSON body,
/// or a transport failure when [error] is set.
class _Reply {
  const _Reply(this.statusCode, [this.body = const {}]) : error = null;
  const _Reply.transportError(DioExceptionType type)
    : statusCode = 0,
      body = const {},
      error = type;

  final int statusCode;
  final Map<String, dynamic> body;
  final DioExceptionType? error;
}

/// Dio adapter that answers per path from a queue. The last reply for a path repeats.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.scripts);

  final Map<String, List<_Reply>> scripts;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final queue = scripts[options.path]!;
    final reply = queue.length > 1 ? queue.removeAt(0) : queue.first;
    if (reply.error != null) {
      throw DioException(requestOptions: options, type: reply.error!);
    }
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _verifyPath = '/api/auth/verify-email';
const _resendPath = '/api/auth/resend-verification';

const _invalidCopy =
    'Liên kết xác minh không hợp lệ, đã hết hạn hoặc đã được sử dụng.';
const _verifiedCopy =
    'Email của bạn đã được xác minh. Bạn có thể đăng nhập ngay bây giờ.';
const _networkCopy = 'Lỗi kết nối mạng, vui lòng thử lại';
const _genericCopy = 'Xác thực thất bại. Vui lòng thử lại.';
const _sentCopy =
    'Nếu email này đang chờ xác minh, một liên kết mới đã được gửi.';

/// Body the handler returns for an invalid, expired or already-used token.
const _invalidTokenProblem = {
  'type': 'https://tools.ietf.org/html/rfc9110#section-15.5.1',
  'title': 'Bad Request',
  'status': 400,
  'detail': 'Invalid or expired token',
};

Future<_ScriptedAdapter> _pumpScreen(
  WidgetTester tester, {
  required String? token,
  required Map<String, List<_Reply>> scripts,
}) async {
  final adapter = _ScriptedAdapter(scripts);
  final dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'))
    ..httpClientAdapter = adapter;
  await tester.pumpWidget(
    MaterialApp(
      home: VerifyEmailScreen(
        token: token,
        authRepository: ApiAuthRepository(dio: dio),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

void main() {
  testWidgets(
    '200 shows the verified state with a login button, sent once with the token',
    (tester) async {
      final adapter = await _pumpScreen(
        tester,
        token: 'tok-123',
        scripts: {
          _verifyPath: [
            const _Reply(200, {
              'message': 'Email verified. You can now log in.',
            }),
          ],
        },
      );

      expect(find.text(_verifiedCopy), findsOneWidget);
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text(_invalidCopy), findsNothing);
      expect(find.text(_networkCopy), findsNothing);
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.data, {'token': 'tok-123'});
    },
  );

  testWidgets(
    '400 shows the invalid state with resend, without the raw backend detail',
    (tester) async {
      await _pumpScreen(
        tester,
        token: 'expired-token',
        scripts: {
          _verifyPath: [const _Reply(400, _invalidTokenProblem)],
        },
      );

      expect(find.text(_invalidCopy), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
      expect(find.text('Invalid or expired token'), findsNothing);
      expect(find.text(_verifiedCopy), findsNothing);
      expect(find.text(_networkCopy), findsNothing);
    },
  );

  testWidgets('400 with a validation-problem body is still the invalid state', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      token: 'bad',
      scripts: {
        _verifyPath: [
          const _Reply(400, {
            'title': 'One or more validation errors occurred.',
            'status': 400,
            'errors': {
              'Token': ['Token is required'],
            },
          }),
        ],
      },
    );

    expect(find.text(_invalidCopy), findsOneWidget);
    expect(find.text(_genericCopy), findsNothing);
  });

  testWidgets(
    'a network error shows retry, not the expired message; retry then verifies',
    (tester) async {
      final adapter = await _pumpScreen(
        tester,
        token: 'tok-123',
        scripts: {
          _verifyPath: [
            const _Reply.transportError(DioExceptionType.connectionError),
            const _Reply(200, {'message': 'ok'}),
          ],
        },
      );

      expect(find.text(_networkCopy), findsOneWidget);
      expect(find.text(_invalidCopy), findsNothing);
      expect(find.text('Email'), findsNothing);

      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text(_verifiedCopy), findsOneWidget);
      expect(find.text(_networkCopy), findsNothing);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.data, {'token': 'tok-123'});
    },
  );

  testWidgets(
    'a 5xx shows the generic retry message, not the expired message',
    (tester) async {
      await _pumpScreen(
        tester,
        token: 'tok-123',
        scripts: {
          _verifyPath: [
            const _Reply(500, {'title': 'Internal Server Error'}),
          ],
        },
      );

      expect(find.text(_genericCopy), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.text(_invalidCopy), findsNothing);
    },
  );

  testWidgets(
    '429 shows the rate-limit message and offers retry, not the expired message',
    (tester) async {
      await _pumpScreen(
        tester,
        token: 'tok-123',
        scripts: {
          _verifyPath: [
            const _Reply(429, {'title': 'Too Many Requests'}),
          ],
        },
      );

      expect(find.text(rateLimitedMessage), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.text(_invalidCopy), findsNothing);
    },
  );

  testWidgets('a missing token is the invalid state and sends no request', (
    tester,
  ) async {
    final adapter = await _pumpScreen(
      tester,
      token: null,
      scripts: {
        _verifyPath: [const _Reply(200)],
      },
    );

    expect(find.text(_invalidCopy), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets(
    'in the invalid state, a valid email enables resend and sends it',
    (tester) async {
      final adapter = await _pumpScreen(
        tester,
        token: 'expired-token',
        scripts: {
          _verifyPath: [const _Reply(400, _invalidTokenProblem)],
          _resendPath: [
            const _Reply(202, {'message': 'ok'}),
          ],
        },
      );

      final resendButton = find.text('Gửi lại email xác minh');
      expect(resendButton, findsNothing);

      await tester.enterText(find.byType(TextField), 'bad-address');
      await tester.pump();
      expect(find.text('Email không hợp lệ'), findsOneWidget);
      expect(resendButton, findsNothing);

      await tester.enterText(find.byType(TextField), 'an@test.com');
      await tester.pump();
      await tester.tap(resendButton);
      await tester.pumpAndSettle();

      expect(find.text(_sentCopy), findsOneWidget);
      expect(adapter.requests.last.path, _resendPath);
      expect(adapter.requests.last.data, {'email': 'an@test.com'});
      // Clear the 60-second cooldown timer so the test ends cleanly.
      await tester.pump(const Duration(seconds: 61));
    },
  );
}
