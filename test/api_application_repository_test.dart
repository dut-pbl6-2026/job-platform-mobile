import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/applications/data/repositories/api_application_repository.dart';

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
