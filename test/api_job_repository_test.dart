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
    });
  });
}
