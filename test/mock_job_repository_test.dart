import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_params.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_model.dart';

void main() {
  late MockJobRepository repository;

  setUp(() {
    repository = MockJobRepository();
  });

  group('MockJobRepository Tests', () {
    test('getJobs returns non-empty paginated job list', () async {
      final result = await repository.getJobs(const JobFilterParams());
      expect(result.isNotEmpty, isTrue);
      expect(result.items.length, lessThanOrEqualTo(10));
      expect(result.total, greaterThan(0));
    });

    test('getJobs filters by keyword correctly', () async {
      final result = await repository.getJobs(
        const JobFilterParams(keyword: 'Flutter'),
      );
      expect(result.items.isNotEmpty, isTrue);
      for (final job in result.items) {
        final matches =
            job.title.toLowerCase().contains('flutter') ||
            job.skills.any((s) => s.toLowerCase().contains('flutter')) ||
            job.description.toLowerCase().contains('flutter');
        expect(matches, isTrue);
      }
    });

    test('getJobs filters by location correctly', () async {
      final result = await repository.getJobs(
        const JobFilterParams(location: 'Đà Nẵng'),
      );
      expect(result.items.isNotEmpty, isTrue);
      for (final job in result.items) {
        expect(job.location, contains('Đà Nẵng'));
      }
    });

    test('getJobs filters by jobType correctly', () async {
      final result = await repository.getJobs(
        const JobFilterParams(jobType: JobType.remote),
      );
      expect(result.items.isNotEmpty, isTrue);
      for (final job in result.items) {
        expect(job.jobType, JobType.remote);
      }
    });

    test('toggleSaveJob flips isSaved status correctly', () async {
      const jobId = 'job-1';
      final initialJob = await repository.getJobById(jobId);
      final initialSaved = initialJob?.isSaved ?? false;

      final newStatus = await repository.toggleSaveJob(jobId);
      expect(newStatus, !initialSaved);

      final updatedJob = await repository.getJobById(jobId);
      expect(updatedJob?.isSaved, newStatus);
    });

    test('getSearchSuggestions returns matching suggestions', () async {
      final suggestions = await repository.getSearchSuggestions('Flut');
      expect(suggestions, contains('Flutter Developer'));
    });
  });
}
