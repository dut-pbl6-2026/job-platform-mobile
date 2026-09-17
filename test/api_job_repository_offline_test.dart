import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:job_platform_mobile/core/services/hive_cache_service.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/api_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_params.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'api_job_repo_offline_test_',
    );
    Hive.init(tempDir.path);
    await HiveCacheService.instance.init();
  });

  tearDown(() async {
    await HiveCacheService.instance.clearAllCache();
    HiveCacheService.instance.resetState();
    await Hive.close();
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  test('ApiJobRepository falls back to Hive cached jobs when offline', () async {
    final cachedJob = JobModel(
      id: 'offline-cached-job-1',
      title: 'Offline Flutter Specialist',
      companyName: 'Offline Tech',
      location: 'Hà Nội',
      category: 'Công nghệ thông tin',
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.middle,
      salaryMin: 20000000,
      salaryMax: 30000000,
      skills: const ['Flutter', 'Hive'],
      description: 'Loaded directly from Hive cache during offline mode',
      requirements: '2+ years experience with Flutter',
      postedAt: DateTime.now(),
    );

    // Populate Hive cache with an offline job
    await HiveCacheService.instance.saveJobs([cachedJob]);

    // Instantiate ApiJobRepository with a non-existent gateway address to force network error
    final repo = ApiJobRepository(gatewayBaseUrl: 'http://127.0.0.1:54321');
    final result = await repo.getJobs(const JobFilterParams());

    expect(result.items.isNotEmpty, isTrue);
    expect(result.items.any((j) => j.id == 'offline-cached-job-1'), isTrue);
    expect(
      result.items.firstWhere((j) => j.id == 'offline-cached-job-1').title,
      equals('Offline Flutter Specialist'),
    );
  });
}
