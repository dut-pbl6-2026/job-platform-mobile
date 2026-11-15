import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/network/dio_provider.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers each request with the response [respond] builds from its options.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  int get count => authorizations.length;

  /// The Authorization header of each request, captured when it is sent: the
  /// interceptor later mutates the same RequestOptions for the retry.
  final List<String?> authorizations = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorizations.add(options.headers['Authorization'] as String?);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(
  int statusCode,
  Map<String, dynamic> body, {
  Map<String, List<String>> headers = const {},
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    },
  );
}

/// The API accepts only `new-access`; anything else is an expired token and gets 401.
ResponseBody _apiRespond(RequestOptions options) {
  if (options.headers['Authorization'] == 'Bearer new-access') {
    return _json(200, {'items': <Object>[]});
  }
  return _json(401, {'message': 'expired'});
}

final _user = UserModel(
  id: 'usr-1',
  name: 'Candidate',
  email: 'candidate@test.com',
  role: UserRole.user,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await AuthSession.instance.clearSession();
    await AuthSession.instance.setSession(
      AuthResult(
        token: 'old-access',
        refreshToken: 'old-refresh',
        user: _user,
        expiresAt: DateTime(2030, 1, 1),
      ),
    );
    provider = DioProvider.instance;
  });

  tearDown(() async {
    provider.dio.httpClientAdapter = _FakeAdapter(_apiRespond);
    await AuthSession.instance.clearSession();
  });

  group('refresh failures on 401', () {
    test(
      '429 on refresh keeps the session and the original request is retried',
      () async {
        var refreshCalls = 0;
        final refresh = _FakeAdapter((_) {
          refreshCalls += 1;
          if (refreshCalls == 1) {
            return _json(
              429,
              {'message': 'rate limited'},
              headers: {
                'retry-after': ['0'],
              },
            );
          }
          return _json(200, {
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
            'user': {
              'id': 'usr-1',
              'email': 'candidate@test.com',
              'fullName': 'Candidate',
              'role': 'User',
            },
          });
        });
        provider.refreshDio.httpClientAdapter = refresh;
        final api = _FakeAdapter(_apiRespond);
        provider.dio.httpClientAdapter = api;

        final res = await provider.dio.get<Map<String, dynamic>>('/api/jobs');

        expect(res.statusCode, 200);
        expect(refresh.count, 2);
        expect(api.authorizations, ['Bearer old-access', 'Bearer new-access']);
        expect(AuthSession.instance.isAuthenticated, isTrue);
        expect(AuthSession.instance.token, 'new-access');
        expect(AuthSession.instance.refreshToken, 'new-refresh');
      },
    );

    test(
      '429 on every refresh attempt keeps the tokens and surfaces the 429, not a logout',
      () async {
        final refresh = _FakeAdapter(
          (_) => _json(
            429,
            {'message': 'rate limited'},
            headers: {
              'retry-after': ['0'],
            },
          ),
        );
        provider.refreshDio.httpClientAdapter = refresh;
        provider.dio.httpClientAdapter = _FakeAdapter(_apiRespond);

        await expectLater(
          provider.dio.get('/api/jobs'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              429,
            ),
          ),
        );

        expect(refresh.count, 3);
        expect(AuthSession.instance.isAuthenticated, isTrue);
        expect(AuthSession.instance.token, 'old-access');
        expect(AuthSession.instance.refreshToken, 'old-refresh');
      },
    );

    test('503 on refresh keeps the session', () async {
      final refresh = _FakeAdapter((_) => _json(503, {'message': 'down'}));
      provider.refreshDio.httpClientAdapter = refresh;
      provider.dio.httpClientAdapter = _FakeAdapter(_apiRespond);

      await expectLater(
        provider.dio.get('/api/jobs'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            503,
          ),
        ),
      );

      expect(refresh.count, 1);
      expect(AuthSession.instance.token, 'old-access');
    });

    test('401 on refresh ends the session', () async {
      final refresh = _FakeAdapter((_) => _json(401, {'message': 'invalid'}));
      provider.refreshDio.httpClientAdapter = refresh;
      provider.dio.httpClientAdapter = _FakeAdapter(_apiRespond);

      await expectLater(
        provider.dio.get('/api/jobs'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );

      expect(refresh.count, 1);
      expect(AuthSession.instance.isAuthenticated, isFalse);
      expect(AuthSession.instance.token, isNull);
      expect(AuthSession.instance.refreshToken, isNull);
    });

    test('403 on refresh ends the session', () async {
      provider.refreshDio.httpClientAdapter = _FakeAdapter(
        (_) => _json(403, {'message': 'forbidden'}),
      );
      provider.dio.httpClientAdapter = _FakeAdapter(_apiRespond);

      await expectLater(
        provider.dio.get('/api/jobs'),
        throwsA(isA<DioException>()),
      );

      expect(AuthSession.instance.token, isNull);
      expect(AuthSession.instance.refreshToken, isNull);
    });
  });
}
