import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/error/error_mapper.dart';
import 'package:job_platform_mobile/core/error/failures.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/features/auth/data/repositories/api_auth_repository.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dio whose every request fails at the transport layer.
Dio _dioWithError(DioException Function(RequestOptions options) build) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(build(options)),
    ),
  );
  return dio;
}

DioException _connectionError(RequestOptions options) => DioException(
  requestOptions: options,
  type: DioExceptionType.connectionError,
  message: 'Connection refused',
);

DioException _unknownTransportError(RequestOptions options) => DioException(
  requestOptions: options,
  type: DioExceptionType.unknown,
  error: 'Socket closed by peer',
);

DioException _httpError(RequestOptions options, int statusCode) => DioException(
  requestOptions: options,
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: options,
    statusCode: statusCode,
    data: {'detail': 'Server detail'},
  ),
);

final _user = UserModel(
  id: 'usr-1',
  name: 'Candidate',
  email: 'candidate@test.com',
  role: UserRole.user,
  createdAt: DateTime(2026, 1, 1),
);

/// Dio adapter that answers every request with one canned status and body,
/// and records the requests it received.
class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter(this.statusCode, this.body);

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

Dio _dioWith(_CannedAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'http://gateway.test'))
    ..httpClientAdapter = adapter;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await AuthSession.instance.clearSession();
  });

  group('ApiAuthRepository login failure paths', () {
    test(
      'network error surfaces networkError and persists no session',
      () async {
        final repo = ApiAuthRepository(dio: _dioWithError(_connectionError));

        await expectLater(
          repo.login(email: 'anyone@test.com', password: 'Password123'),
          throwsA(
            isA<AuthFailure>().having(
              (f) => f.code,
              'code',
              AuthFailure.networkError,
            ),
          ),
        );

        expect(AuthSession.instance.isAuthenticated, isFalse);
        expect(AuthSession.instance.token, isNull);
        expect(await const FlutterSecureStorage().readAll(), isEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_user'), isNull);
      },
    );

    test('transport error without response is also a network error', () async {
      final repo = ApiAuthRepository(
        dio: _dioWithError(_unknownTransportError),
      );

      await expectLater(
        repo.login(email: 'anyone@test.com', password: 'Password123'),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.networkError,
          ),
        ),
      );
      expect(AuthSession.instance.isAuthenticated, isFalse);
    });

    test('HTTP 401 maps to invalidCredentials and persists nothing', () async {
      final repo = ApiAuthRepository(
        dio: _dioWithError((o) => _httpError(o, 401)),
      );

      await expectLater(
        repo.login(email: 'anyone@test.com', password: 'Password123'),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.invalidCredentials,
          ),
        ),
      );
      expect(AuthSession.instance.isAuthenticated, isFalse);
    });
  });

  group('ApiAuthRepository other auth actions fail on network error', () {
    test('register does not persist a session when offline', () async {
      final repo = ApiAuthRepository(dio: _dioWithError(_connectionError));

      await expectLater(
        repo.register(
          name: 'Candidate',
          email: 'candidate@test.com',
          password: 'Password123',
          role: UserRole.user,
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.networkError,
          ),
        ),
      );
      expect(AuthSession.instance.isAuthenticated, isFalse);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    });

    test('forgotPassword reports a network error instead of success', () async {
      final repo = ApiAuthRepository(dio: _dioWithError(_connectionError));

      await expectLater(
        repo.forgotPassword(email: 'candidate@test.com'),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.networkError,
          ),
        ),
      );
    });

    test('resetPassword reports a network error instead of success', () async {
      final repo = ApiAuthRepository(dio: _dioWithError(_connectionError));

      await expectLater(
        repo.resetPassword(token: 'reset-token', newPassword: 'Password123'),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.networkError,
          ),
        ),
      );
    });
  });

  group('ApiAuthRepository session restore', () {
    Future<void> seedStoredSession() async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'stored-access-token',
        'auth_refresh': 'stored-refresh-token',
      });
      SharedPreferences.setMockInitialValues({
        'auth_user': jsonEncode(_user.toJson()),
      });
    }

    test('load restores a stored session', () async {
      await seedStoredSession();

      await AuthSession.instance.load();

      expect(AuthSession.instance.isLoaded, isTrue);
      expect(AuthSession.instance.isAuthenticated, isTrue);
      expect(AuthSession.instance.token, 'stored-access-token');
      expect(AuthSession.instance.currentUser?.email, 'candidate@test.com');
    });

    test('a restored session is cleared when the server rejects it', () async {
      await seedStoredSession();
      await AuthSession.instance.load();

      final repo = ApiAuthRepository(
        dio: _dioWithError((o) => _httpError(o, 401)),
      );
      await repo.validateRestoredSession();

      expect(AuthSession.instance.isAuthenticated, isFalse);
      const storage = FlutterSecureStorage();
      expect(await storage.containsKey(key: 'auth_token'), isFalse);
      expect(await storage.containsKey(key: 'auth_refresh'), isFalse);
    });

    test('a restored session is kept when the server is unreachable', () async {
      await seedStoredSession();
      await AuthSession.instance.load();

      final repo = ApiAuthRepository(dio: _dioWithError(_connectionError));
      await repo.validateRestoredSession();

      expect(AuthSession.instance.isAuthenticated, isTrue);
      expect(AuthSession.instance.token, 'stored-access-token');
    });

    test('a restored session is kept when the server errors', () async {
      await seedStoredSession();
      await AuthSession.instance.load();

      final repo = ApiAuthRepository(
        dio: _dioWithError((o) => _httpError(o, 500)),
      );
      await repo.validateRestoredSession();

      expect(AuthSession.instance.isAuthenticated, isTrue);
    });

    test('validation does nothing without a restored session', () async {
      final repo = ApiAuthRepository(
        dio: _dioWithError((o) => _httpError(o, 401)),
      );

      await repo.validateRestoredSession();

      expect(AuthSession.instance.isAuthenticated, isFalse);
    });

    test(
      'deactivated account (isActive: false) clears restored session',
      () async {
        await seedStoredSession();
        await AuthSession.instance.load();

        final repo = ApiAuthRepository(
          dio: _dioWith(
            _CannedAdapter(200, {
              'id': 'usr-1',
              'email': 'candidate@test.com',
              'fullName': 'Candidate',
              'role': 'User',
              'isActive': false,
            }),
          ),
        );
        await repo.validateRestoredSession();

        expect(AuthSession.instance.isAuthenticated, isFalse);
      },
    );

    test(
      'validateRestoredSession syncs updated server user profile and migrates SharedPreferences',
      () async {
        await seedStoredSession();
        await AuthSession.instance.load();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('auth_user'), isNull);
        expect(
          await const FlutterSecureStorage().containsKey(key: 'auth_user'),
          isTrue,
        );

        final repo = ApiAuthRepository(
          dio: _dioWith(
            _CannedAdapter(200, {
              'id': 'usr-1',
              'email': 'candidate@test.com',
              'fullName': 'Promoted Recruiter',
              'role': 'Recruiter',
              'companyId': 'comp-99',
              'isActive': true,
            }),
          ),
        );
        await repo.validateRestoredSession();

        expect(AuthSession.instance.isAuthenticated, isTrue);
        expect(AuthSession.instance.currentUser?.name, 'Promoted Recruiter');
        expect(AuthSession.instance.currentUser?.role, UserRole.recruiter);
        expect(AuthSession.instance.companyId, 'comp-99');
      },
    );
  });

  group('Register response contract (auth-svc PR #44)', () {
    test(
      '202 with { message } completes without a user id, tokens or session',
      () async {
        final adapter = _CannedAdapter(202, {
          'message': 'Check your email to verify your account.',
        });
        final repo = ApiAuthRepository(dio: _dioWith(adapter));

        await expectLater(
          repo.register(
            name: 'Candidate',
            email: 'candidate@test.com',
            password: 'Password123',
            role: UserRole.user,
          ),
          completes,
        );

        expect(AuthSession.instance.isAuthenticated, isFalse);
        expect(AuthSession.instance.token, isNull);
        expect(await const FlutterSecureStorage().readAll(), isEmpty);
        // Only the register call is made; the client never logs in afterwards.
        expect(adapter.requests.map((r) => r.path), ['/api/auth/register']);
      },
    );

    test('409 duplicate email maps to emailExists', () async {
      final adapter = _CannedAdapter(409, {'detail': 'Email already exists'});
      final repo = ApiAuthRepository(dio: _dioWith(adapter));

      await expectLater(
        repo.register(
          name: 'Candidate',
          email: 'candidate@test.com',
          password: 'Password123',
          role: UserRole.user,
        ),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.code,
            'code',
            AuthFailure.emailExists,
          ),
        ),
      );
      expect(AuthSession.instance.isAuthenticated, isFalse);
    });
  });

  group('Login 401 copy (wrong password and unverified look the same)', () {
    test(
      'a 401 from login shows the neutral credentials-or-verify message',
      () async {
        final repo = ApiAuthRepository(
          dio: _dioWith(_CannedAdapter(401, {'detail': 'Invalid credentials'})),
        );

        Object? caught;
        try {
          await repo.login(email: 'anyone@test.com', password: 'Password123');
        } catch (e) {
          caught = e;
        }

        expect(caught, isA<AuthFailure>());
        expect(
          authFailureToMessage(caught! as AuthFailure),
          loginCredentialsOrVerifyMessage,
        );
        expect(AuthSession.instance.isAuthenticated, isFalse);
      },
    );
  });
}
