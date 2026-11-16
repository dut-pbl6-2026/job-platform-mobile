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

      final openJobs = await repository.getMyJobs(status: 'Đang mở');
      expect(openJobs.every((j) => j.status == 'Đang mở'), isTrue);
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
      expect(jobs.first.status, 'Chờ duyệt');
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

      test('maps form labels to FullTime, PartTime and Internship', () async {
        final expected = {
          'Toàn thời gian': 'FullTime',
          'Bán thời gian': 'PartTime',
          'Thực tập': 'Internship',
        };
        for (final entry in expected.entries) {
          final body = await capturePayload(
            build(employment: entry.key, experience: 'Mid'),
          );
          expect(body['employmentType'], entry.value);
        }
      });

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

    test('maps each UI status to a job-svc JobStatus value', () async {
      expect((await captureJobsQuery('Đang mở'))['status'], 'Active');
      expect((await captureJobsQuery('Chờ duyệt'))['status'], 'Pending');
      expect((await captureJobsQuery('Đã đóng'))['status'], 'Closed');
    });

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
  });
}
