import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/profile/data/repositories/api_profile_repository.dart';
import 'package:job_platform_mobile/features/profile/domain/models/profile_model.dart';

void main() {
  group('ApiProfileRepository Tests', () {
    test('Can instantiate ApiProfileRepository', () {
      final repo = ApiProfileRepository();
      expect(repo, isNotNull);
    });

    test('reads use mocks only when the flag is injected', () async {
      final dio = _offlineDio();
      final repo = ApiProfileRepository(dio: dio, enableMockFallback: true);

      final profile = await repo.getMyProfile();
      expect(profile, isNotNull);
      expect(profile.fullName.isNotEmpty, isTrue);
    });

    test('reads are an error when mocks are off (the default)', () async {
      final repo = ApiProfileRepository(dio: _offlineDio());

      await expectLater(repo.getMyProfile(), throwsA(isA<Exception>()));
    });

    test('a 401 never returns a mock profile', () async {
      final repo = ApiProfileRepository(
        dio: _statusDio(401),
        enableMockFallback: true,
      );

      await expectLater(repo.getMyProfile(), throwsA(isA<Exception>()));
    });

    test('writes never report success without the server', () async {
      // Even with mocks enabled, a write that never left the device must fail:
      // the UI would otherwise say "saved" and lose the edit.
      final repo = ApiProfileRepository(
        dio: _offlineDio(),
        enableMockFallback: true,
      );

      await expectLater(
        repo.updateProfile(
          ProfileModel(
            id: 'p1',
            userId: 'u1',
            fullName: 'Nguyễn An',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        repo.addSkill(
          const SkillModel(
            id: 'skill-new',
            name: 'GraphQL',
            proficiency: 4,
            yearsOfExperience: 2,
          ),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(repo.deleteSkill('skill-1'), throwsA(isA<Exception>()));
    });

    test('an error message never carries the server detail', () async {
      final repo = ApiProfileRepository(
        dio: _statusDio(
          500,
          data: {
            'title': 'Internal',
            'detail': 'Npgsql.PostgresException at /src/Profile/Handler.cs',
            'traceId': '00-abc-def-00',
          },
        ),
      );

      Object? caught;
      try {
        await repo.getMyProfile();
      } catch (error) {
        caught = error;
      }

      final message = caught.toString();
      expect(message, contains('Không thể tải thông tin hồ sơ cá nhân'));
      expect(message, isNot(contains('Npgsql')));
      expect(message, isNot(contains('traceId')));
    });

    test(
      'getOrCreateProfile creates the profile when /me answers 404',
      () async {
        final calls = <String>[];
        final dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              calls.add('${options.method} ${options.path}');
              if (options.method == 'GET') {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.badResponse,
                    response: Response(
                      requestOptions: options,
                      statusCode: 404,
                    ),
                  ),
                );
                return;
              }
              expect(options.path, '/api/profiles');
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'id': 'profile-1',
                    'userId': 'user-1',
                    'fullName': 'Nhà tuyển dụng',
                    'createdAt': DateTime(2026).toIso8601String(),
                    'updatedAt': DateTime(2026).toIso8601String(),
                  },
                ),
              );
            },
          ),
        );

        final profile = await ApiProfileRepository(
          dio: dio,
        ).getOrCreateProfile();

        expect(calls, ['GET /api/profiles/me', 'POST /api/profiles']);
        expect(profile.id, 'profile-1');
        expect(profile.fullName, 'Nhà tuyển dụng');
      },
    );

    test('Throws exception on HTTP error with response', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'Unauthorized'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );
      final repo = ApiProfileRepository(dio: dio);

      expect(() => repo.getMyProfile(), throwsA(isA<Exception>()));
    });
  });
}

Dio _offlineDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          error: 'Connection refused',
          type: DioExceptionType.connectionError,
        ),
      ),
    ),
  );
  return dio;
}

Dio _statusDio(int status, {Map<String, dynamic>? data}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: status,
            data: data ?? const {},
          ),
        ),
      ),
    ),
  );
  return dio;
}
