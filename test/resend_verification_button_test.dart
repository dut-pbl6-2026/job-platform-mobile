import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/error/error_mapper.dart';
import 'package:job_platform_mobile/features/auth/data/repositories/api_auth_repository.dart';
import 'package:job_platform_mobile/features/auth/presentation/widgets/resend_verification_button.dart';

/// Dio adapter that answers every request with one status and body, and records the requests.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _sent = 'Nếu email này đang chờ xác minh, một liên kết mới đã được gửi.';
const _sendButton = 'Gửi lại email xác minh';
const _coolingLabel = 'Gửi lại sau 60 giây';

Future<_FakeAdapter> _pumpButton(
  WidgetTester tester,
  int statusCode,
  Map<String, dynamic> body,
) async {
  final adapter = _FakeAdapter(statusCode, body);
  final dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'))
    ..httpClientAdapter = adapter;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ResendVerificationButton(
          email: 'an@test.com',
          authRepository: ApiAuthRepository(dio: dio),
        ),
      ),
    ),
  );
  return adapter;
}

void main() {
  testWidgets(
    '202 shows the generic message and starts the 60-second cooldown',
    (tester) async {
      final adapter = await _pumpButton(tester, 202, {
        'message':
            'If this email is awaiting verification, a new link was sent.',
      });

      await tester.tap(find.text(_sendButton));
      await tester.pumpAndSettle();

      expect(find.text(_sent), findsOneWidget);
      expect(find.text(_coolingLabel), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(adapter.requests.single.data, {'email': 'an@test.com'});
    },
  );

  testWidgets('429 shows the rate-limit message and keeps the button enabled', (
    tester,
  ) async {
    await _pumpButton(tester, 429, {'title': 'Too Many Requests'});

    await tester.tap(find.text(_sendButton));
    await tester.pumpAndSettle();

    expect(find.text(rateLimitedMessage), findsOneWidget);
    expect(find.text(_sent), findsNothing);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'a tap during the cooldown is ignored, and the button enables again after 60 seconds',
    (tester) async {
      final adapter = await _pumpButton(tester, 202, {'message': 'ok'});

      await tester.tap(find.text(_sendButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_coolingLabel));
      await tester.pumpAndSettle();
      expect(adapter.requests, hasLength(1));

      await tester.pump(const Duration(seconds: 60));
      expect(find.text(_sendButton), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNotNull,
      );
    },
  );
}
