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

        final repo = ApiRecruiterRepository(dio: dio);

        // Reads fall back gracefully
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
}
