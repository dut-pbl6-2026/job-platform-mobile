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

    test('fromJson reads the name of a nested category object', () {
      final json = _searchItemJson()
        ..remove('categoryName')
        ..['category'] = {'id': 'cat-1', 'name': 'Công nghệ thông tin'};
      final job = JobModel.fromJson(json);

      expect(job.category, 'Công nghệ thông tin');
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
        expect(JobType.fromString('unknown'), JobType.other);
        expect(JobType.fromString(''), JobType.other);
      },
    );

    test('JobType maps backend Contract and Internship with labels', () {
      expect(JobType.fromString('Contract'), JobType.contract);
      expect(JobType.fromString('Internship'), JobType.internship);
      expect(JobType.fromString('Hợp đồng'), JobType.contract);
      expect(JobType.fromString('Thực tập'), JobType.internship);
      expect(JobType.contract.displayName, 'Hợp đồng');
      expect(JobType.internship.displayName, 'Thực tập');
      expect(JobType.other.displayName, 'Khác');
    });

    test('ExperienceLevel maps backend Entry and Mid explicitly', () {
      expect(ExperienceLevel.fromString('Entry'), ExperienceLevel.fresher);
      expect(ExperienceLevel.fromString('Mid'), ExperienceLevel.middle);
      expect(ExperienceLevel.fromString('Senior'), ExperienceLevel.senior);
      expect(ExperienceLevel.fromString('Lead'), ExperienceLevel.lead);
      // Mobile's own spellings still resolve, so cached entries keep their value.
      expect(ExperienceLevel.fromString('Fresher'), ExperienceLevel.fresher);
      expect(ExperienceLevel.fromString('Middle'), ExperienceLevel.middle);
    });

    test('ExperienceLevel never maps unknown or missing values to junior', () {
      expect(ExperienceLevel.fromString('Principal'), ExperienceLevel.other);
      expect(ExperienceLevel.fromString(''), ExperienceLevel.other);
      expect(ExperienceLevel.fromString('Junior'), ExperienceLevel.junior);

      final json = _jobDetailJson()..remove('experienceLevel');
      expect(JobModel.fromJson(json).experienceLevel, ExperienceLevel.other);
    });

    test('fromJson maps the job-svc JobDetailDto shape', () {
      final job = JobModel.fromJson(_jobDetailJson());

      expect(job.id, 'd2b1c0a4-6f2e-4c1e-9a7b-3f0e8c5d1a21');
      expect(job.companyName, 'Công ty ABC');
      expect(job.category, 'IT');
      expect(job.jobType, JobType.contract);
      expect(job.experienceLevel, ExperienceLevel.fresher);
      expect(job.salaryMin, 15000000);
      expect(job.postedAt.toUtc(), DateTime.utc(2026, 11, 2, 3));
    });

    test('fromJson maps every backend employment and experience value', () {
      for (final entry in {
        'FullTime': JobType.fullTime,
        'PartTime': JobType.partTime,
        'Contract': JobType.contract,
        'Internship': JobType.internship,
      }.entries) {
        final json = _jobDetailJson()..['employmentType'] = entry.key;
        expect(JobModel.fromJson(json).jobType, entry.value, reason: entry.key);
      }
      for (final entry in {
        'Entry': ExperienceLevel.fresher,
        'Mid': ExperienceLevel.middle,
        'Senior': ExperienceLevel.senior,
        'Lead': ExperienceLevel.lead,
      }.entries) {
        final json = _jobDetailJson()..['experienceLevel'] = entry.key;
        expect(
          JobModel.fromJson(json).experienceLevel,
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('fromJson maps an unknown employmentType to other, not fullTime', () {
      final json = _jobDetailJson()..['employmentType'] = 'Freelance-Contract';
      expect(JobModel.fromJson(json).jobType, JobType.other);
    });

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

/// Job detail shape returned by job-svc (`GET /api/jobs/{id}`, JobDetailDto).
Map<String, dynamic> _jobDetailJson() => {
  'id': 'd2b1c0a4-6f2e-4c1e-9a7b-3f0e8c5d1a21',
  'title': 'Lập trình viên .NET',
  'description': 'Mô tả công việc',
  'companyId': 'a12b3c4d-0000-0000-0000-000000000001',
  'companyName': 'Công ty ABC',
  'location': 'Đà Nẵng',
  'salaryMin': 15000000,
  'salaryMax': 25000000,
  'salaryCurrency': 'VND',
  'categoryId': 'c34d5e6f-0000-0000-0000-000000000002',
  'categoryName': 'IT',
  'requirements': 'Yêu cầu...',
  'benefits': 'Quyền lợi...',
  'employmentType': 'Contract',
  'experienceLevel': 'Entry',
  'status': 'Active',
  'viewCount': 4,
  'createdAt': '2026-11-02T03:00:00Z',
  'updatedAt': '2026-11-02T03:00:00Z',
};
