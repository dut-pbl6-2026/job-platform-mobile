import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_config.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_params.dart';

void main() {
  group('JobFilterData Configuration Tests', () {
    test('contains all 4 contract job types', () {
      expect(JobFilterData.jobTypes.length, 4);
      final ids = JobFilterData.jobTypes.map((e) => e.id).toList();
      expect(
        ids,
        containsAll(['internship', 'part_time', 'full_time', 'freelance']),
      );
    });

    test('contains 34 domestic locations across 3 main regions of Vietnam', () {
      expect(JobFilterData.domesticLocations.length, 34);

      final north = JobFilterData.domesticLocations
          .where((l) => l.region == 'Miền Bắc')
          .toList();
      final central = JobFilterData.domesticLocations
          .where((l) => l.region == 'Miền Trung - Tây Nguyên')
          .toList();
      final south = JobFilterData.domesticLocations
          .where((l) => l.region == 'Miền Nam')
          .toList();

      expect(north.length, 12);
      expect(central.length, 11);
      expect(south.length, 11);
    });

    test('contains Japan international location with 10 key regions', () {
      expect(JobFilterData.internationalLocations.length, 1);
      final jp = JobFilterData.internationalLocations.first;
      expect(jp.code, 'JP');
      expect(jp.name, contains('Nhật Bản'));
      expect(jp.regions.length, 10);
      expect(jp.regions, contains('Tokyo'));
      expect(jp.regions, contains('Osaka'));
    });

    test('contains 10 category groups with child specializations', () {
      expect(JobFilterData.categories.length, 10);

      final it = JobFilterData.categories.firstWhere(
        (c) => c.id == 'it_software',
      );
      expect(it.name, 'Công nghệ thông tin & Phần mềm');
      expect(it.specializations.length, 12);
      expect(
        it.specializations.map((s) => s.id),
        containsAll([
          'software_engineer',
          'brse',
          'mobile_dev',
          'ai_data',
          'qa_qc',
          'devops_cloud',
        ]),
      );
    });

    test(
      'contains additional filters for experience, workplace, and salary',
      () {
        expect(JobFilterData.experienceLevels.length, 5);
        expect(JobFilterData.workplaceTypes.length, 3);
        expect(JobFilterData.salaryRanges.length, 7);

        final vnd = JobFilterData.salaryRanges
            .where((r) => r.currency == 'VND')
            .toList();
        final jpy = JobFilterData.salaryRanges
            .where((r) => r.currency == 'JPY')
            .toList();

        expect(vnd.length, 5);
        expect(jpy.length, 2);
      },
    );
  });

  group('JobFilterParams Commercial Extensions', () {
    test('tracks active filters for specialization and workplaceType', () {
      const params = JobFilterParams(
        specialization: 'Mobile App Developer',
        workplaceType: 'remote',
      );

      expect(params.hasActiveFilters, isTrue);
      expect(params.activeFilterCount, 2);
    });

    test('tracks active filters for international location', () {
      const params = JobFilterParams(
        country: 'JP',
        internationalRegion: 'Tokyo',
      );

      expect(params.hasActiveFilters, isTrue);
      expect(params.activeFilterCount, 1);
    });

    test('clearAllFilters resets all commercial attributes', () {
      const params = JobFilterParams(
        location: 'Đà Nẵng',
        specialization: 'Software Engineer',
        workplaceType: 'hybrid',
        salaryRangeId: '20m_40m',
        country: 'VN',
      );

      final cleared = params.clearAllFilters();
      expect(cleared.hasActiveFilters, isFalse);
      expect(cleared.activeFilterCount, 0);
      expect(cleared.specialization, isNull);
      expect(cleared.workplaceType, isNull);
      expect(cleared.salaryRangeId, isNull);
      expect(cleared.country, isNull);
    });
  });

  group('MockJobRepository Commercial Filters', () {
    late MockJobRepository repository;

    setUp(() {
      repository = MockJobRepository();
    });

    test('filters jobs by workplaceType remote', () async {
      final result = await repository.getJobs(
        const JobFilterParams(workplaceType: 'remote'),
      );
      expect(result.items.isNotEmpty, isTrue);
      for (final job in result.items) {
        final isRemote =
            job.location.toLowerCase().contains('remote') ||
            job.location.toLowerCase().contains('từ xa') ||
            job.jobType.name == 'remote';
        expect(isRemote, isTrue);
      }
    });

    test('filters jobs by specialization', () async {
      final result = await repository.getJobs(
        const JobFilterParams(specialization: 'AI'),
      );
      expect(result.items.isNotEmpty, isTrue);
      expect(
        result.items.any((j) => j.title.toLowerCase().contains('ai')),
        isTrue,
      );
    });
  });
}
