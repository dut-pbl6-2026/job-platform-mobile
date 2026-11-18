import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/recruiter/data/repositories/api_recruiter_repository.dart';
import 'package:job_platform_mobile/features/recruiter/data/repositories/mock_recruiter_repository.dart';
import 'package:job_platform_mobile/features/recruiter/domain/models/recruiter_models.dart';

void main() {
  group('MockRecruiterRepository Tests', () {
    late MockRecruiterRepository repository;

    setUp(() {
      repository = MockRecruiterRepository();
    });

    test('isMock returns true', () {
      expect(repository.isMock, isTrue);
    });

    test('getMyJobs returns initial jobs and filters by status', () async {
      final jobs = await repository.getMyJobs();
      expect(jobs.isNotEmpty, isTrue);
      expect(jobs.any((j) => j.title == 'UI/UX Designer'), isTrue);

      final openJobs = await repository.getMyJobs(status: 'Active');
      expect(openJobs.every((j) => j.isOpen), isTrue);
      final closedJobs = await repository.getMyJobs(status: 'Closed');
      expect(closedJobs.every((j) => j.isClosed), isTrue);
    });

    test(
      'getCandidateApplications returns candidates and updates status',
      () async {
        final candidates = await repository.getCandidateApplications();
        expect(candidates.isNotEmpty, isTrue);
        expect(candidates.any((c) => c.name == 'Khoa Phạm'), isTrue);

        final updated = await repository.updateCandidateStatus(
          'cand_1',
          'Được nhận',
        );
        expect(updated, isTrue);

        final afterUpdate = await repository.getCandidateApplications();
        final cand1 = afterUpdate.firstWhere((c) => c.id == 'cand_1');
        expect(cand1.status, 'Được nhận');
      },
    );

    test('postJob prepends job to list', () async {
      final newId = await repository.postJob(
        const PostJobParams(
          title: 'Senior DevOps Engineer',
          location: 'Đà Nẵng · Onsite',
          description: 'Quản trị hạ tầng đám mây và CI/CD.',
        ),
      );

      expect(newId.isNotEmpty, isTrue);
      final jobs = await repository.getMyJobs();
      expect(jobs.first.title, 'Senior DevOps Engineer');
      expect(jobs.first.status, 'Active');
    });

    test('getDashboardStats returns valid metrics', () async {
      final stats = await repository.getDashboardStats();
      expect(stats.activeJobsCount, greaterThan(0));
      expect(stats.viewsCount, greaterThan(0));
    });
  });

  group('ApiRecruiterRepository Tests with Gateway and Error Handling', () {
    test(
      'reads fall back gracefully to Mock when offline but writes surface errors',
      () async {
        final dio = Dio(
          BaseOptions(
            baseUrl: 'http://127.0.0.1:59999', // unreachable port
            connectTimeout: const Duration(milliseconds: 100),
            receiveTimeout: const Duration(milliseconds: 100),
          ),
        );

        final repo = ApiRecruiterRepository(dio: dio, enableMockFallback: true);

        // Reads fall back when mocks are explicitly injected
        final jobs = await repo.getMyJobs();
        expect(jobs.isNotEmpty, isTrue);
        expect(repo.isMock, isTrue);

        final candidates = await repo.getCandidateApplications(
          jobId: 'some-job',
        );
        expect(candidates.isNotEmpty, isTrue);

        final stats = await repo.getDashboardStats();
        expect(stats.activeJobsCount, greaterThan(0));

        // Writes surface errors instead of faking success
        expect(
          () => repo.postJob(
            const PostJobParams(
              title: 'Test Job',
              location: 'Hà Nội',
              companyId: '00000000-0000-0000-0000-000000000001',
              description: 'Mô tả công việc kiểm thử',
            ),
          ),
          throwsA(isA<Exception>()),
        );

        expect(
          () => repo.updateCandidateStatus('cand_1', 'Được nhận'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('a 403 never shows invented jobs, candidates or stats', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://unused.invalid'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 403,
                data: {'title': 'Forbidden'},
              ),
            ),
          ),
        ),
      );
      // Even with mocks enabled, an authorisation answer is not a failure to
      // paper over: the recruiter must see that the session/company is wrong.
      final repo = ApiRecruiterRepository(dio: dio, enableMockFallback: true);

      await expectLater(repo.getMyJobs(), throwsA(isA<DioException>()));
      await expectLater(
        repo.getCandidateApplications(jobId: 'job-1'),
        throwsA(isA<DioException>()),
      );
      await expectLater(repo.getDashboardStats(), throwsA(isA<DioException>()));
      expect(repo.isMock, isFalse);
    });

    group('postJob sends canonical backend enum values', () {
      // Captures the POST /api/jobs body and answers 201 so no request leaves.
      Future<Map<String, dynamic>> capturePayload(PostJobParams params) async {
        late Map<String, dynamic> body;
        final dio = Dio(BaseOptions(baseUrl: 'http://unused.invalid'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              body = Map<String, dynamic>.from(options.data as Map);
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 201,
                  data: {'id': 'job-new'},
                ),
              );
            },
          ),
        );
        await ApiRecruiterRepository(dio: dio).postJob(params);
        return body;
      }

      PostJobParams build({String? employment, String? experience}) {
        return PostJobParams(
          title: 'Flutter Developer',
          location: 'Hà Nội',
          companyId: '00000000-0000-0000-0000-000000000001',
          description: 'Mô tả công việc kiểm thử',
          employmentType: employment ?? 'Toàn thời gian',
          experienceLevel: experience,
        );
      }

      test(
        'maps form labels to FullTime, PartTime, Contract and Internship',
        () async {
          final expected = {
            'Toàn thời gian': 'FullTime',
            'Bán thời gian': 'PartTime',
            'Hợp đồng': 'Contract',
            'Thực tập': 'Internship',
          };
          for (final entry in expected.entries) {
            final body = await capturePayload(
              build(employment: entry.key, experience: 'Mid'),
            );
            expect(body['employmentType'], entry.value);
          }
        },
      );

      test(
        'PostJobParams.parseSalaryInput parses numeric ranges and detects inverted bounds',
        () {
          final vnd = PostJobParams.parseSalaryInput(
            '15.000.000 – 25.000.000 ₫',
          );
          expect(vnd.min, 15000000);
          expect(vnd.max, 25000000);
          expect(vnd.currency, 'VND');
          expect(vnd.isInvalidRange, isFalse);

          final usd = PostJobParams.parseSalaryInput('1500 - 2500 USD');
          expect(usd.min, 1500);
          expect(usd.max, 2500);
          expect(usd.currency, 'USD');

          final inverted = PostJobParams.parseSalaryInput(
            '30.000.000 - 15.000.000',
          );
          expect(inverted.isInvalidRange, isTrue);
        },
      );

      test('sends the canonical experience level unchanged', () async {
        for (final level in ['Entry', 'Mid', 'Senior', 'Lead']) {
          final body = await capturePayload(build(experience: level));
          expect(body['experienceLevel'], level);
        }
      });

      test(
        'rejects a missing experience level instead of sending Entry',
        () async {
          await expectLater(capturePayload(build()), throwsA(isA<Exception>()));
        },
      );
    });

    test('postJob rejects when recruiter companyId cannot be resolved', () {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:59999',
          connectTimeout: const Duration(milliseconds: 100),
          receiveTimeout: const Duration(milliseconds: 100),
        ),
      );
      final repo = ApiRecruiterRepository(dio: dio);

      expect(
        () => repo.postJob(
          const PostJobParams(
            title: 'No Company Job',
            location: 'TP.HCM',
            description: 'Mô tả',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ApiRecruiterRepository job status filter', () {
    // Captures the outgoing /api/jobs/recruiter query and answers with an empty page.
    Future<Map<String, dynamic>> captureJobsQuery(String? status) async {
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
                data: {'items': <dynamic>[]},
              ),
            );
          },
        ),
      );
      await ApiRecruiterRepository(dio: dio).getMyJobs(status: status);
      return query;
    }

    test(
      'maps UI statuses to Active/Closed and publishes legacy pending',
      () async {
        expect((await captureJobsQuery('Active'))['status'], 'Active');
        expect((await captureJobsQuery('Đang mở'))['status'], 'Active');
        expect((await captureJobsQuery('Chờ duyệt'))['status'], 'Active');
        expect((await captureJobsQuery('Pending'))['status'], 'Active');
        expect((await captureJobsQuery('Closed'))['status'], 'Closed');
        expect((await captureJobsQuery('Đã đóng'))['status'], 'Closed');
      },
    );

    test('never sends the non-existent Draft status', () async {
      final query = await captureJobsQuery('Chờ duyệt');
      expect(query['status'], isNot('Draft'));
    });

    test('omits status when no status filter is given', () async {
      expect(await captureJobsQuery(null), isEmpty);
    });

    test('omits status for a UI value with no backend equivalent', () async {
      expect((await captureJobsQuery('Nháp')).containsKey('status'), isFalse);
    });

    test(
      'getMyJobs sends canonical size parameter instead of pageSize',
      () async {
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
                  data: {'items': <dynamic>[]},
                ),
              );
            },
          ),
        );
        await ApiRecruiterRepository(dio: dio).getMyJobs(page: 1, pageSize: 15);
        expect(query['page'], 1);
        expect(query['size'], 15);
        expect(query.containsKey('pageSize'), isFalse);
      },
    );
  });

  group('Recruiter camelCase DTOs, companyId resolution, and CV download', () {
    test(
      'CandidateApplication enforces camelCase and null pending matchScore',
      () {
        final pending = CandidateApplication.fromJson({
          'id': 'app-1',
          'jobId': 'job-1',
          'applicantId': 'usr-1',
          'applicantName': 'An',
          'jobTitle': 'Mobile',
          'status': 'Pending',
          'cvUrl': '/api/applications/cv/an.pdf',
          'scoreStatus': 'pending',
        });
        expect(pending.jobId, 'job-1');
        expect(pending.applicantId, 'usr-1');
        expect(pending.cvUrl, '/api/applications/cv/an.pdf');
        expect(pending.matchScore, isNull);
        expect(pending.isScorePending, isTrue);

        final snakeOnly = CandidateApplication.fromJson({
          'id': 'app-2',
          'job_id': 'job-snake',
          'applicant_id': 'usr-snake',
          'cv_url': '/api/applications/cv/snake.pdf',
          'match_score': 88,
        });
        expect(snakeOnly.jobId, isEmpty);
        expect(snakeOnly.applicantId, isEmpty);
        expect(snakeOnly.cvUrl, isNull);
        expect(snakeOnly.matchScore, isNull);
      },
    );

    test('RecruiterJob.fromJson enforces camelCase contract', () {
      final job = RecruiterJob.fromJson({
        'id': 'job-1',
        'title': 'Flutter Dev',
        'status': 'Active',
        'applicationsCount': 4,
        'viewCount': 99,
        'location': 'Đà Nẵng',
        'salaryMin': 1500,
        'salaryMax': 2500,
        'salaryCurrency': 'USD',
        'createdAt': '2026-11-18T00:00:00Z',
        'employmentType': 'FullTime',
        'experienceLevel': 'Senior',
        'categoryId': 'cat-1',
      });
      expect(job.applicationsCount, 4);
      expect(job.viewsCount, 99);
      expect(job.salaryMin, 1500);
      expect(job.salaryCurrency, 'USD');
      expect(job.employmentType, 'FullTime');
      expect(job.categoryId, 'cat-1');

      final snakeOnly = RecruiterJob.fromJson({
        'id': 'job-2',
        'title': 'Snake',
        'salary_min': 1000,
        'applications_count': 5,
        'view_count': 10,
        'employment_type': 'FullTime',
        'category_id': 'cat-snake',
      });
      expect(snakeOnly.salaryMin, isNull);
      expect(snakeOnly.applicationsCount, 0);
      expect(snakeOnly.viewsCount, 0);
      expect(snakeOnly.employmentType, isNull);
      expect(snakeOnly.categoryId, isNull);
    });

    test(
      'postJob and updateJob resolve companyId via /api/companies/mine (never /api/profiles/me)',
      () async {
        final paths = <String>[];
        late Map<String, dynamic> postBody;
        late Map<String, dynamic> putBody;

        final dio = Dio(BaseOptions(baseUrl: 'http://unused.invalid'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              paths.add('${options.method} ${options.path}');
              if (options.path == '/api/companies/mine') {
                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 200,
                    data: {'id': 'comp-from-mine', 'name': 'Acme'},
                  ),
                );
                return;
              }
              if (options.method == 'POST' && options.path == '/api/jobs') {
                postBody = Map<String, dynamic>.from(options.data as Map);
                handler.resolve(
                  Response(
                    requestOptions: options,
                    statusCode: 201,
                    data: {'id': 'job-created'},
                  ),
                );
                return;
              }
              if (options.method == 'PUT' &&
                  options.path == '/api/jobs/job-created') {
                putBody = Map<String, dynamic>.from(options.data as Map);
                handler.resolve(
                  Response(requestOptions: options, statusCode: 200),
                );
                return;
              }
              handler.reject(DioException(requestOptions: options));
            },
          ),
        );

        final repo = ApiRecruiterRepository(dio: dio);
        const params = PostJobParams(
          title: 'Backend Engineer',
          location: 'Đà Nẵng',
          description: 'Mô tả',
          experienceLevel: 'Mid',
        );
        final createdId = await repo.postJob(params);
        await repo.updateJob(createdId, params);

        expect(paths, isNot(contains(contains('/api/profiles/me'))));
        expect(postBody['companyId'], 'comp-from-mine');
        expect(putBody['companyId'], 'comp-from-mine');
      },
    );
  });
}
