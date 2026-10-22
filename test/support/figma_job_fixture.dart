import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_filter_params.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_model.dart';
import 'package:job_platform_mobile/features/jobs/domain/repositories/job_repository.dart';

/// Figma examples are confined to deterministic rendering tests.
class FigmaJobFixture extends MockJobRepository {
  final jobs = [
    JobModel(
      id: 'figma-badoo',
      title: 'UI/UX Designer',
      companyName: 'Badoo Inc.',
      location: 'Bangalore, CA',
      category: 'Design',
      experienceLevel: ExperienceLevel.intern,
      description: '',
      requirements: '',
      postedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    JobModel(
      id: 'figma-meta',
      title: 'Sr. UI/UX Designer',
      companyName: 'Meta Inc.',
      location: 'Bangalore, India',
      category: 'Design',
      experienceLevel: ExperienceLevel.senior,
      description: '',
      requirements: '',
      postedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  @override
  Future<PaginatedJobs> getJobs(JobFilterParams params) async => PaginatedJobs(
    items: jobs,
    total: jobs.length,
    page: 0,
    size: 10,
    totalPages: 1,
  );
}
