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

    test(
      'Falls back gracefully to mock only when enableMockFallback is true',
      () async {
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
        final repo = ApiApplicationRepository(
          dio: dio,
          enableMockFallback: true,
        );

        final list = await repo.getMyApplications();
        expect(list.isNotEmpty, isTrue);

        final detail = await repo.getApplicationById(list.first.id);
        expect(detail, isNotNull);

        final hasApp = await repo.hasApplied('job-1');
        expect(hasApp, isTrue);

        final nonExistentApp = await repo.hasApplied('job-unknown-999');
        expect(nonExistentApp, isFalse);
      },
    );

    test(
      'Does NOT fabricate mock data by default when Gateway is offline (BUG-04)',
      () async {
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

        await expectLater(
          repo.getMyApplications(),
          throwsA(isA<ApplicationRepositoryException>()),
        );
        await expectLater(
          repo.getApplicationById('app-1'),
          throwsA(isA<ApplicationRepositoryException>()),
        );
        expect(await repo.hasApplied('job-1'), isFalse);
      },
    );

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

      test(
        'server 500 error throws sanitized user-facing copy without leaking internal detail (SEC-05)',
        () async {
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
              isA<ApplicationRepositoryException>().having(
                (e) => e.toString(),
                'message',
                allOf(
                  contains('tạm thời gián đoạn'),
                  isNot(contains('CV storage unavailable')),
                ),
              ),
            ),
          );
        },
      );

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

    test(
      'applyJob sends §8 multipart fields and adapts 201 Created response',
      () async {
        final dio = Dio();
        FormData? capturedForm;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              capturedForm = options.data as FormData;
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {
                    'id': 'app-201',
                    'job_id': 'job-uuid-1',
                    'applicant_id': 'usr-uuid-1',
                    'status': 'pending',
                    'cv_url': '/api/applications/cv/cv.pdf',
                  },
                ),
              );
            },
          ),
        );
        final repo = ApiApplicationRepository(dio: dio);
        final result = await repo.applyJob(
          const ApplyJobParams(
            jobId: 'job-uuid-1',
            jobTitle: 'Mobile Engineer',
            companyName: 'VNG',
            coverLetter: 'Hello',
            cvFileName: 'cv.pdf',
            cvBytes: [1, 2, 3],
          ),
        );

        expect(capturedForm, isNotNull);
        expect(Map.fromEntries(capturedForm!.fields), {
          'job_id': 'job-uuid-1',
          'cover_letter': 'Hello',
        });
        expect(capturedForm!.files.map((e) => e.key), contains('cv_file'));
        expect(result.id, 'app-201');
        expect(result.jobId, 'job-uuid-1');
        expect(result.jobTitle, 'Mobile Engineer');
        expect(result.companyName, 'VNG');
        expect(result.cvUrl, '/api/applications/cv/cv.pdf');
      },
    );

    test(
      'downloadCvBytes fetches gateway-relative path and rejects unsafe URLs',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://gateway.test'));
        String? requestedPath;
        ResponseType? requestedResponseType;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requestedPath = options.path;
              requestedResponseType = options.responseType;
              handler.resolve(
                Response<List<int>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const [37, 80, 68, 70],
                ),
              );
            },
          ),
        );

        final repo = ApiApplicationRepository(dio: dio);
        final bytes = await repo.downloadCvBytes(
          '/api/applications/cv/resume.pdf',
        );
        expect(requestedPath, '/api/applications/cv/resume.pdf');
        expect(requestedResponseType, ResponseType.bytes);
        expect(bytes, [37, 80, 68, 70]);

        await expectLater(
          repo.downloadCvBytes('/api/applications/cv/../secret.pdf'),
          throwsA(isA<ApplicationRepositoryException>()),
        );
        await expectLater(
          repo.downloadCvBytes('http://evil.example/cv.pdf'),
          throwsA(isA<ApplicationRepositoryException>()),
        );
      },
    );
  });
}
