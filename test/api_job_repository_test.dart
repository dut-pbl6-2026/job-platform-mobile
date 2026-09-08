import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/api_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_params.dart';

void main() {
  group('ApiJobRepository Tests', () {
    test('Can instantiate ApiJobRepository without platform error', () {
      final repo = ApiJobRepository();
      expect(repo, isNotNull);
    });

    test('Falls back gracefully to mock when Gateway is offline', () async {
      final repo = ApiJobRepository(gatewayBaseUrl: 'http://localhost:9999');
      final result = await repo.getJobs(const JobFilterParams());
      expect(result.items.isNotEmpty, isTrue);

      final job = await repo.getJobById('job-1');
      expect(job, isNotNull);
      expect(job!.title, contains('Flutter'));

      final suggestions = await repo.getSearchSuggestions('Flutter');
      expect(suggestions, contains('Flutter Developer'));
    });
  });
}
