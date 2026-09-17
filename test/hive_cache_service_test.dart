import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:job_platform_mobile/core/services/hive_cache_service.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cache_test_');
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

  final testJob = JobModel(
    id: 'test-job-1',
    title: 'Senior Flutter Engineer',
    companyName: 'Tech Corp',
    location: 'Đà Nẵng',
    category: 'Công nghệ thông tin',
    jobType: JobType.fullTime,
    experienceLevel: ExperienceLevel.senior,
    salaryMin: 25000000,
    salaryMax: 40000000,
    skills: const ['Flutter', 'Dart', 'Bloc'],
    description: 'Build awesome cross-platform apps',
    requirements: '3+ years experience with Flutter',
    postedAt: DateTime.now(),
  );

  group('HiveCacheService Jobs Caching (OFFLINE-01)', () {
    test('saveJobs and getCachedJobs work correctly', () async {
      await HiveCacheService.instance.saveJobs([testJob]);
      final cached = await HiveCacheService.instance.getCachedJobs();

      expect(cached, isNotEmpty);
      expect(cached.length, 1);
      expect(cached.first.id, equals('test-job-1'));
      expect(cached.first.title, equals('Senior Flutter Engineer'));

      final lastCachedTime = HiveCacheService.instance.getLastCachedTime();
      expect(lastCachedTime, isNotNull);
    });

    test('saveJobDetail and getCachedJobDetail work correctly', () async {
      await HiveCacheService.instance.saveJobDetail(testJob);
      final cachedDetail = await HiveCacheService.instance.getCachedJobDetail(
        'test-job-1',
      );

      expect(cachedDetail, isNotNull);
      expect(cachedDetail?.id, equals('test-job-1'));
      expect(cachedDetail?.companyName, equals('Tech Corp'));

      final nonExistent = await HiveCacheService.instance.getCachedJobDetail(
        'non-existent',
      );
      expect(nonExistent, isNull);
    });
  });

  group('HiveCacheService Recent Searches (OFFLINE-01)', () {
    test(
      'saveRecentSearch saves queries with newest first and deduplication',
      () async {
        await HiveCacheService.instance.saveRecentSearch('Flutter');
        await HiveCacheService.instance.saveRecentSearch('React');
        await HiveCacheService.instance.saveRecentSearch(
          'Flutter',
        ); // duplicate

        final searches = await HiveCacheService.instance.getRecentSearches();
        expect(searches, equals(['Flutter', 'React']));
        expect(searches.length, 2);
      },
    );

    test('removeRecentSearch removes single query', () async {
      await HiveCacheService.instance.saveRecentSearch('Golang');
      await HiveCacheService.instance.saveRecentSearch('Python');

      await HiveCacheService.instance.removeRecentSearch('Golang');
      final searches = await HiveCacheService.instance.getRecentSearches();
      expect(searches, equals(['Python']));
    });

    test('clearRecentSearches empties the list', () async {
      await HiveCacheService.instance.saveRecentSearch('Java');
      await HiveCacheService.instance.saveRecentSearch('Kotlin');

      await HiveCacheService.instance.clearRecentSearches();
      final searches = await HiveCacheService.instance.getRecentSearches();
      expect(searches, isEmpty);
    });

    test('ignores empty or whitespace-only search queries', () async {
      await HiveCacheService.instance.saveRecentSearch('   ');
      final searches = await HiveCacheService.instance.getRecentSearches();
      expect(searches, isEmpty);
    });
  });
}
