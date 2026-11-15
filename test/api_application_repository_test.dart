import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/applications/data/repositories/api_application_repository.dart';
import 'package:job_platform_mobile/features/applications/domain/models/application_model.dart';

void main() {
  group('ApiApplicationRepository Tests', () {
    test('Can instantiate ApiApplicationRepository', () {
      final repo = ApiApplicationRepository();
      expect(repo, isNotNull);
    });

    test('Falls back gracefully to mock when Gateway is offline', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Connection refused',
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );
      final repo = ApiApplicationRepository(dio: dio);

      final list = await repo.getMyApplications();
      expect(list.isNotEmpty, isTrue);

      final detail = await repo.getApplicationById(list.first.id);
      expect(detail, isNotNull);

      final hasApp = await repo.hasApplied('job-1');
      expect(hasApp, isTrue);

      final nonExistentApp = await repo.hasApplied('job-unknown-999');
      expect(nonExistentApp, isFalse);
    });

    group('applyJob failure paths', () {
      final params = ApplyJobParams(
        jobId: 'job-1',
        jobTitle: 'Flutter Developer',
        companyName: 'Acme',
        cvFileName: 'cv.pdf',
        cvBytes: const [1, 2, 3],
      );

      test('network error throws and never reports success', () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                  message: 'Connection refused',
                ),
              );
            },
          ),
        );
        final repo = ApiApplicationRepository(dio: dio);

        await expectLater(
          repo.applyJob(params),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              allOf(contains('kết nối'), isNot(contains('Connection refused'))),
            ),
          ),
        );
      });

      test('server error surfaces the server message', () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: options,
                    statusCode: 500,
                    data: {'detail': 'CV storage unavailable'},
                  ),
                ),
              );
            },
          ),
        );
        final repo = ApiApplicationRepository(dio: dio);

        await expectLater(
          repo.applyJob(params),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('CV storage unavailable'),
            ),
          ),
        );
      });

      test('duplicate application (409) throws a user-facing error', () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: options,
                    statusCode: 409,
                    data: {'message': 'Already applied'},
                  ),
                ),
              );
            },
          ),
        );
        final repo = ApiApplicationRepository(dio: dio);

        await expectLater(
          repo.applyJob(params),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('đã nộp hồ sơ'),
            ),
          ),
        );
      });
    });

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
                  statusCode: 409,
                  data: {'message': 'Already applied'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );
      final repo = ApiApplicationRepository(dio: dio);

      expect(() => repo.getMyApplications(), throwsA(isA<Exception>()));
    });
  });
}
