import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/api_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_params.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_model.dart';

void main() {
  group('ApiJobRepository Tests', () {
    test('Can instantiate ApiJobRepository without platform error', () {
      final repo = ApiJobRepository();
      expect(repo, isNotNull);
    });

    test(
      'a detail missing required fields fails instead of rendering blank',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://unused.invalid'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'id': 'job-1'},
              ),
            ),
          ),
        );

        await expectLater(
          ApiJobRepository(dio: dio).getJobById('job-1'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'mocks are used when injected and the gateway is unreachable',
      () async {
        final repo = ApiJobRepository(
          gatewayBaseUrl: 'http://localhost:9999',
          enableMockFallback: true,
        );
        final result = await repo.getJobs(const JobFilterParams());
        expect(result.items.isNotEmpty, isTrue);

        final job = await repo.getJobById('job-1');
        expect(job, isNotNull);
        expect(job!.title, contains('Flutter'));

        final suggestions = await repo.getSearchSuggestions('Flutter');
        expect(suggestions, contains('Flutter Developer'));
      },
    );

    test(
      'mocks are off by default: an unreachable gateway is an error',
      () async {
        final repo = ApiJobRepository(gatewayBaseUrl: 'http://localhost:9999');

        // Mock data is a compile-time opt-in (ENABLE_MOCKS), never the default.
        await expectLater(
          repo.getJobs(const JobFilterParams()),
          throwsA(isA<DioException>()),
        );
        await expectLater(
          repo.getJobById('job-1'),
          throwsA(isA<DioException>()),
        );
      },
    );

    test('a 401 never yields mock jobs, even with mocks enabled', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://unused.invalid'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'title': 'Unauthorized'},
              ),
            ),
          ),
        ),
      );
      final repo = ApiJobRepository(dio: dio, enableMockFallback: true);

      await expectLater(
        repo.getJobs(const JobFilterParams()),
        throwsA(isA<DioException>()),
      );
      await expectLater(repo.getJobById('job-1'), throwsA(isA<DioException>()));
    });

    test('a 5xx may still use mocks when they are enabled', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://unused.invalid'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 503,
                data: {'title': 'Service unavailable'},
              ),
            ),
          ),
        ),
      );
      final repo = ApiJobRepository(dio: dio, enableMockFallback: true);

      final result = await repo.getJobs(const JobFilterParams());
      expect(result.items.isNotEmpty, isTrue);
    });

    group('search filters use backend parameter names and values', () {
      // Captures the outgoing query and answers with an empty page.
      Future<Map<String, dynamic>> captureQuery(JobFilterParams params) async {
        late Map<String, dynamic> query;
        final dio = Dio(BaseOptions(baseUrl: 'http://unused.invalid'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              query = Map<String, dynamic>.from(options.queryParameters);
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'items': <dynamic>[], 'total': 0},
                ),
              );
            },
          ),
        );
        await ApiJobRepository(dio: dio).getJobs(params);
        return query;
      }

      test('employment type is sent as employmentType with FullTime', () async {
        final query = await captureQuery(
          const JobFilterParams(jobType: JobType.fullTime),
        );
        expect(query['employmentType'], 'FullTime');
        expect(query.containsKey('jobType'), isFalse);
      });

      test('each supported employment type uses its canonical value', () async {
        final expected = {
          JobType.partTime: 'PartTime',
          JobType.contract: 'Contract',
          JobType.internship: 'Internship',
        };
        for (final entry in expected.entries) {
          final query = await captureQuery(JobFilterParams(jobType: entry.key));
          expect(query['employmentType'], entry.value);
        }
      });

      test('employment types without a backend value are not sent', () async {
        for (final type in [
          JobType.remote,
          JobType.hybrid,
          JobType.freelance,
          JobType.other,
        ]) {
          final query = await captureQuery(JobFilterParams(jobType: type));
          expect(query.containsKey('employmentType'), isFalse, reason: '$type');
          expect(query.containsKey('jobType'), isFalse, reason: '$type');
        }
      });

      test(
        'experience uses experienceLevel with Entry, Mid, Senior, Lead',
        () async {
          final expected = {
            ExperienceLevel.fresher: 'Entry',
            ExperienceLevel.middle: 'Mid',
            ExperienceLevel.senior: 'Senior',
            ExperienceLevel.lead: 'Lead',
          };
          for (final entry in expected.entries) {
            final query = await captureQuery(
              JobFilterParams(experienceLevel: entry.key),
            );
            expect(query['experienceLevel'], entry.value);
          }
        },
      );

      test('experience without a backend value is not sent', () async {
        for (final level in [
          ExperienceLevel.junior,
          ExperienceLevel.intern,
          ExperienceLevel.other,
        ]) {
          final query = await captureQuery(
            JobFilterParams(experienceLevel: level),
          );
          expect(
            query.containsKey('experienceLevel'),
            isFalse,
            reason: '$level',
          );
        }
      });

      test('supported filters use search-svc parameter names', () async {
        final query = await captureQuery(
          const JobFilterParams(
            keyword: 'flutter',
            location: 'Hà Nội',
            category: 'IT',
            skills: ['Dart', 'Flutter'],
            salaryMin: 10000000,
            salaryMax: 20000000,
            sortBy: 'salary_desc',
          ),
        );
        expect(query['q'], 'flutter');
        expect(query['location'], 'Hà Nội');
        expect(query['category'], 'IT');
        expect(query['skills'], 'Dart,Flutter');
        expect(query['skillOp'], 'or');
        expect(query['minSalary'], '10000000');
        expect(query['maxSalary'], '20000000');
        expect(query['sortBy'], 'salary_desc');
      });

      test('filters without a search-svc parameter are not sent', () async {
        final query = await captureQuery(
          const JobFilterParams(
            specialization: 'AI',
            workplaceType: 'remote',
            country: 'JP',
            internationalRegion: 'Tokyo',
            salaryRangeId: '10m_20m',
            currency: 'JPY',
            includeNegotiable: false,
          ),
        );
        for (final key in [
          'specialization',
          'workplaceType',
          'country',
          'region',
          'salaryRange',
          'currency',
          'includeNegotiable',
        ]) {
          expect(query.containsKey(key), isFalse, reason: key);
        }
      });

      test('sortBy values search-svc does not know are omitted', () async {
        for (final sort in ['newest', 'relevance']) {
          final query = await captureQuery(JobFilterParams(sortBy: sort));
          expect(query.containsKey('sortBy'), isFalse, reason: sort);
        }
      });

      test(
        'getJobById returns cached crawled sha256 job without calling /api/jobs/{id}',
        () async {
          const crawledId =
              '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
          final requestedPaths = <String>[];
          final dio = Dio(BaseOptions(baseUrl: 'http://unused.invalid'));
          dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requestedPaths.add(options.path);
                if (options.path == '/api/search/jobs') {
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      statusCode: 200,
                      data: {
                        'items': [
                          {
                            'id': crawledId,
                            'title': 'Crawled Flutter Job',
                            'companyName': 'External Co',
                            'location': 'Hà Nội',
                            'currency': 'USD',
                          },
                        ],
                        'total': 1,
                        'page': 0,
                        'size': 20,
                        'totalPages': 1,
                      },
                    ),
                  );
                  return;
                }
                handler.reject(DioException(requestOptions: options));
              },
            ),
          );

          final repo = ApiJobRepository(dio: dio);
          await repo.getJobs(const JobFilterParams(keyword: 'Flutter'));
          final detail = await repo.getJobById(crawledId);

          expect(detail, isNotNull);
          expect(detail!.title, 'Crawled Flutter Job');
          expect(detail.salaryCurrency, 'USD');
          expect(detail.isExternalCrawledJob, isTrue);
          expect(requestedPaths, ['/api/search/jobs']);
        },
      );
    });
  });
}
