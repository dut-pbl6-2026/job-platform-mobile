import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
