import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/utils/format_utils.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_params.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_model.dart';

void main() {
  group('FormatUtils Tests', () {
    test(
      'formatVND correctly formats numbers with dots and currency symbol',
      () {
        expect(FormatUtils.formatVND(15000000), '15.000.000 VNĐ');
        expect(FormatUtils.formatVND(500000), '500.000 VNĐ');
        expect(FormatUtils.formatVND(0), '0 VNĐ');
      },
    );

    test('formatSalaryRange handles negotiable and range values', () {
      expect(FormatUtils.formatSalaryRange(isNegotiable: true), 'Thỏa thuận');
      expect(
        FormatUtils.formatSalaryRange(min: 15000000, max: 25000000),
        '15.000.000 - 25.000.000 VNĐ',
      );
      expect(FormatUtils.formatSalaryRange(min: 20000000), 'Từ 20.000.000 VNĐ');
      expect(
        FormatUtils.formatSalaryRange(max: 30000000),
        'Tới 30.000.000 VNĐ',
      );
    });

    test('timeAgo returns friendly Vietnamese text', () {
      final now = DateTime.now();
      expect(FormatUtils.timeAgo(now), 'Vừa xong');
      expect(
        FormatUtils.timeAgo(now.subtract(const Duration(minutes: 10))),
        '10 phút trước',
      );
      expect(
        FormatUtils.timeAgo(now.subtract(const Duration(hours: 3))),
        '3 giờ trước',
      );
      expect(
        FormatUtils.timeAgo(now.subtract(const Duration(days: 4))),
        '4 ngày trước',
      );
    });
  });

  group('JobModel & JobFilterParams Tests', () {
    test('JobModel serialization fromJson and toJson works accurately', () {
      final now = DateTime(2026, 8, 30, 10, 0);
      final job = JobModel(
        id: 'test-job-1',
        title: 'Senior Flutter Developer',
        companyName: 'FPT Software',
        location: 'Đà Nẵng',
        salaryMin: 30000000,
        salaryMax: 45000000,
        category: 'Công nghệ thông tin',
        jobType: JobType.fullTime,
        experienceLevel: ExperienceLevel.senior,
        skills: const ['Flutter', 'Dart'],
        description: 'Mô tả công việc...',
        requirements: 'Yêu cầu...',
        benefits: 'Quyền lợi...',
        postedAt: now,
      );

      final json = job.toJson();
      expect(json['id'], 'test-job-1');
      expect(json['title'], 'Senior Flutter Developer');
      expect(json['jobType'], 'Full-time');
      expect(json['experienceLevel'], 'Senior');

      final reconstructed = JobModel.fromJson(json);
      expect(reconstructed.id, job.id);
      expect(reconstructed.title, job.title);
      expect(reconstructed.companyName, job.companyName);
      expect(reconstructed.salaryMin, 30000000);
      expect(reconstructed.jobType, JobType.fullTime);
      expect(reconstructed.experienceLevel, ExperienceLevel.senior);
      expect(reconstructed.skills, ['Flutter', 'Dart']);
    });

    test('fromJson maps the camelCase search item shape', () {
      final job = JobModel.fromJson(_searchItemJson());

      expect(job.id, 'job-search-1');
      expect(job.companyName, 'FPT Software');
      expect(job.jobType, JobType.partTime);
      expect(job.category, 'Công nghệ thông tin');
      // search-svc emits 7 fractional digits; Dart keeps microseconds.
      expect(job.postedAt, DateTime.utc(2026, 11, 1, 8, 30, 0, 0, 123456));
      expect(job.expiresAt, DateTime.parse('2026-12-31T00:00:00Z'));
      expect(job.salaryMin, 30000000);
      expect(job.skills, ['Flutter', 'Dart']);
    });

    test('fromJson maps the camelCase job detail shape', () {
      final json = _searchItemJson()
        ..remove('skills')
        ..remove('expiresAt')
        ..remove('currency')
        ..remove('status')
        ..addAll({
          'salaryCurrency': 'VND',
          'experienceLevel': 'Senior',
          'employmentType': 'FullTime',
          'recruiterId': 'recruiter-1',
          'viewCount': 12,
        });
      final job = JobModel.fromJson(json);

      expect(job.jobType, JobType.fullTime);
      expect(job.category, 'Công nghệ thông tin');
      expect(
        job.postedAt.toUtc(),
        DateTime.utc(2026, 11, 1, 8, 30, 0, 0, 123456),
      );
      expect(job.expiresAt, isNull);
      expect(job.skills, isEmpty);
      expect(job.viewCount, 12);
    });

    test(
      'fromJson falls back to empty category and null expiry when absent',
      () {
        final json = _searchItemJson()
          ..['categoryName'] = null
          ..remove('expiresAt');
        final job = JobModel.fromJson(json);

        expect(job.category, 'Khác');
        expect(job.expiresAt, isNull);
      },
    );

    test(
      'fromJson uses the current time only when no timestamp is present',
      () {
        final before = DateTime.now();
        final json = _searchItemJson()..remove('createdAt');
        final job = JobModel.fromJson(json);

        expect(job.postedAt.isBefore(before), isFalse);
        expect(
          job.postedAt.difference(DateTime.now()).inSeconds.abs() < 5,
          isTrue,
        );
      },
    );

    test('fromJson ignores a nested category object instead of throwing', () {
      final json = _searchItemJson()
        ..remove('categoryName')
        ..['category'] = {'id': 'cat-1', 'name': 'Công nghệ thông tin'};
      final job = JobModel.fromJson(json);

      expect(job.category, 'Khác');
    });

    test('fromJson still reads cached entries written with legacy keys', () {
      final legacy = _searchItemJson()
        ..remove('employmentType')
        ..remove('createdAt')
        ..remove('categoryName')
        ..addAll({
          'jobType': 'Part-time',
          'postedAt': '2026-11-01T08:30:00.000Z',
          'category': 'Kinh doanh',
        });
      final job = JobModel.fromJson(legacy);

      expect(job.jobType, JobType.partTime);
      expect(job.category, 'Kinh doanh');
      expect(job.postedAt.toUtc(), DateTime.utc(2026, 11, 1, 8, 30));
    });

    test(
      'JobType.fromString accepts backend enum names and display values',
      () {
        expect(JobType.fromString('FullTime'), JobType.fullTime);
        expect(JobType.fromString('PartTime'), JobType.partTime);
        expect(JobType.fromString('Full-time'), JobType.fullTime);
        expect(JobType.fromString('Toàn thời gian'), JobType.fullTime);
        expect(JobType.fromString('remote'), JobType.remote);
        expect(JobType.fromString('unknown'), JobType.fullTime);
      },
    );

    test('JobFilterParams calculates active filters properly', () {
      const defaultParams = JobFilterParams();
      expect(defaultParams.hasActiveFilters, isFalse);
      expect(defaultParams.activeFilterCount, 0);

      final filtered = defaultParams.copyWith(
        keyword: 'Flutter',
        location: 'Đà Nẵng',
        jobType: JobType.remote,
      );

      expect(filtered.hasActiveFilters, isTrue);
      // keyword is counted in hasActiveFilters but activeFilterCount counts categorical filters
      expect(filtered.activeFilterCount, 2);

      final cleared = filtered.clearAllFilters();
      expect(cleared.hasActiveFilters, isFalse);
      expect(cleared.activeFilterCount, 0);
    });
  });
}

/// Camel-case item shape returned by search-svc (`/api/search/jobs`).
Map<String, dynamic> _searchItemJson() => {
  'id': 'job-search-1',
  'title': 'Flutter Developer',
  'description': 'Mô tả công việc',
  'companyId': 'company-1',
  'companyName': 'FPT Software',
  'location': 'Đà Nẵng',
  'salaryMin': 30000000,
  'salaryMax': 45000000,
  'currency': 'VND',
  'categoryId': 'cat-1',
  'categoryName': 'Công nghệ thông tin',
  'employmentType': 'PartTime',
  'experienceLevel': 'Senior',
  'status': 'Active',
  'recruiterId': 'recruiter-1',
  'createdAt': '2026-11-01T08:30:00.1234567Z',
  'updatedAt': '2026-11-02T08:30:00Z',
  'expiresAt': '2026-12-31T00:00:00Z',
  'requirements': 'Yêu cầu...',
  'benefits': 'Quyền lợi...',
  'skills': ['Flutter', 'Dart'],
};
