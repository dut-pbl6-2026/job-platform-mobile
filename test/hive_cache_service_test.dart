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

    test('encrypts Hive boxes when AES-256 key is provided (SEC-01)', () async {
      await HiveCacheService.instance.clearAllCache();
      HiveCacheService.instance.resetState();
      await Hive.close();

      final aesKey = List<int>.generate(32, (i) => i + 1);
      await HiveCacheService.instance.init(encryptionKeyOverride: aesKey);

      await HiveCacheService.instance.saveJobs([testJob]);
      final cached = await HiveCacheService.instance.getCachedJobs();
      expect(cached.length, 1);
      expect(cached.first.id, 'test-job-1');
    });

    test('isolates cache entries per user namespace', () async {
      HiveCacheService.instance.setActiveUserNamespace('user-a');
      await HiveCacheService.instance.saveJobs([testJob]);
      await HiveCacheService.instance.saveJobDetail(testJob);
      await HiveCacheService.instance.saveRecentSearch('Flutter');

      HiveCacheService.instance.setActiveUserNamespace('user-b');
      expect(await HiveCacheService.instance.getCachedJobs(), isEmpty);
      expect(
        await HiveCacheService.instance.getCachedJobDetail('test-job-1'),
        isNull,
      );
      expect(await HiveCacheService.instance.getRecentSearches(), isEmpty);

      HiveCacheService.instance.setActiveUserNamespace('user-a');
      expect(await HiveCacheService.instance.getCachedJobs(), hasLength(1));
      expect(
        (await HiveCacheService.instance.getCachedJobDetail('test-job-1'))?.id,
        'test-job-1',
      );
      expect(await HiveCacheService.instance.getRecentSearches(), ['Flutter']);
    });

    test('expires cached jobs and details after 24h TTL', () async {
      final t0 = DateTime(2026, 11, 18, 8, 0);
      await HiveCacheService.instance.saveJobs([testJob], now: t0);
      await HiveCacheService.instance.saveJobDetail(testJob, now: t0);

      final beforeExpiry = t0.add(const Duration(hours: 23));
      expect(
        await HiveCacheService.instance.getCachedJobs(now: beforeExpiry),
        hasLength(1),
      );
      expect(
        await HiveCacheService.instance.getCachedJobDetail(
          'test-job-1',
          now: beforeExpiry,
        ),
        isNotNull,
      );
      expect(
        HiveCacheService.instance.getLastCachedTime(now: beforeExpiry),
        isNotNull,
      );

      final afterExpiry = t0.add(const Duration(hours: 24, minutes: 1));
      expect(
        HiveCacheService.instance.getLastCachedTime(now: afterExpiry),
        isNull,
      );
      expect(
        await HiveCacheService.instance.getCachedJobs(now: afterExpiry),
        isEmpty,
      );
      expect(
        await HiveCacheService.instance.getCachedJobDetail(
          'test-job-1',
          now: afterExpiry,
        ),
        isNull,
      );
    });
  });
}
