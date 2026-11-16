import 'dart:io';
import 'package:dio/dio.dart';
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

    // An unreachable gateway is a transport failure, which may serve cached
    // data. The test binding answers real requests with 400, so the failure is
    // injected instead of relying on a network error.
    final dio = _offlineDio();
    final repo = ApiJobRepository(dio: dio);
    final result = await repo.getJobs(const JobFilterParams());

    expect(result.items.isNotEmpty, isTrue);
    expect(result.items.any((j) => j.id == 'offline-cached-job-1'), isTrue);
    expect(
      result.items.firstWhere((j) => j.id == 'offline-cached-job-1').title,
      equals('Offline Flutter Specialist'),
    );
  });

  test('a server answer (400) is an error, not cached data', () async {
    final cachedJob = JobModel(
      id: 'offline-cached-job-1',
      title: 'Offline Flutter Specialist',
      companyName: 'Offline Tech',
      location: 'Hà Nội',
      category: 'Công nghệ thông tin',
      jobType: JobType.fullTime,
      experienceLevel: ExperienceLevel.middle,
      skills: const ['Flutter'],
      description: 'Cached job',
      requirements: '2+ years experience',
      postedAt: DateTime.now(),
    );
    await HiveCacheService.instance.saveJobs([cachedJob]);

    final dio = Dio(BaseOptions(baseUrl: 'http://gateway.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {'title': 'Bad request'},
            ),
          ),
        ),
      ),
    );
    final repo = ApiJobRepository(dio: dio);

    // A 400 is the server answering, so stale cache (and mock data) must not
    // pretend the search succeeded.
    await expectLater(
      repo.getJobs(const JobFilterParams()),
      throwsA(isA<DioException>()),
    );
  });
}

Dio _offlineDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://offline.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'offline',
        ),
      ),
    ),
  );
  return dio;
}
