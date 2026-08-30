import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/utils/format_utils.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_params.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_model.dart';

void main() {
  group('FormatUtils Tests', () {
    test('formatVND correctly formats numbers with dots and currency symbol', () {
      expect(FormatUtils.formatVND(15000000), '15.000.000 ₫');
      expect(FormatUtils.formatVND(500000), '500.000 ₫');
      expect(FormatUtils.formatVND(0), '0 ₫');
    });

    test('formatSalaryRange handles negotiable and range values', () {
      expect(
        FormatUtils.formatSalaryRange(isNegotiable: true),
        'Thỏa thuận',
      );
      expect(
        FormatUtils.formatSalaryRange(min: 15000000, max: 25000000),
        '15.000.000 - 25.000.000 ₫',
      );
      expect(
        FormatUtils.formatSalaryRange(min: 20000000),
        'Từ 20.000.000 ₫',
      );
      expect(
        FormatUtils.formatSalaryRange(max: 30000000),
        'Tới 30.000.000 ₫',
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
