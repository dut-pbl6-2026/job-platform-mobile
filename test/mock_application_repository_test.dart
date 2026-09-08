import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/applications/data/repositories/mock_application_repository.dart';
import 'package:job_platform_mobile/features/applications/domain/models/application_model.dart';

void main() {
  late MockApplicationRepository repository;

  setUp(() {
    repository = MockApplicationRepository();
    repository.clear();
  });

  group('MockApplicationRepository Tests', () {
    test('getMyApplications returns seeded list of applications', () async {
      final list = await repository.getMyApplications();
      expect(list.isNotEmpty, true);
      expect(list.length, greaterThanOrEqualTo(4));
    });

    test('getMyApplications filters by status correctly (APP-01-03)', () async {
      final reviewedList = await repository.getMyApplications(
        status: ApplicationStatus.reviewed,
      );
      expect(reviewedList.every((app) => app.status == ApplicationStatus.reviewed), true);

      final acceptedList = await repository.getMyApplications(
        status: ApplicationStatus.accepted,
      );
      expect(acceptedList.every((app) => app.status == ApplicationStatus.accepted), true);
    });

    test('getApplicationById retrieves correct application or null', () async {
      final app = await repository.getApplicationById('app-001');
      expect(app, isNotNull);
      expect(app!.id, 'app-001');
      expect(app.companyName, 'FPT Software');

      final nonExistent = await repository.getApplicationById('non-existent-id');
      expect(nonExistent, isNull);
    });

    test('hasApplied returns true for seeded jobs and false for new jobs', () async {
      expect(await repository.hasApplied('job-1'), true);
      expect(await repository.hasApplied('brand-new-job-999'), false);
    });

    test('applyJob successfully submits new application (APP-01-01, MOB-01-04)', () async {
      const newJobId = 'job-new-123';
      final params = const ApplyJobParams(
        jobId: newJobId,
        jobTitle: 'Flutter Tech Lead',
        companyName: 'MoMo Payment',
        coverLetter: 'Tôi rất hào hứng được ứng tuyển vào MoMo.',
        cvFileName: 'Nguyen_Van_An_CV_MoMo.pdf',
        cvFileSize: 410 * 1024,
      );

      final submitted = await repository.applyJob(params);
      expect(submitted.jobId, newJobId);
      expect(submitted.jobTitle, 'Flutter Tech Lead');
      expect(submitted.companyName, 'MoMo Payment');
      expect(submitted.status, ApplicationStatus.pending);
      expect(submitted.cvFileName, 'Nguyen_Van_An_CV_MoMo.pdf');
      expect(await repository.hasApplied(newJobId), true);

      // Verify it appears in getMyApplications list
      final allApps = await repository.getMyApplications();
      expect(allApps.first.jobId, newJobId);
    });

    test('applyJob prevents duplicate applications for the same job (APP-01-02)', () async {
      // job-1 was already applied in seed data
      const existingJobId = 'job-1';
      final params = const ApplyJobParams(
        jobId: existingJobId,
        jobTitle: 'Senior Flutter Developer',
        companyName: 'FPT Software',
        cvFileName: 'My_Duplicate_CV.pdf',
      );

      expect(
        () async => await repository.applyJob(params),
        throwsA(isA<Exception>()),
      );
    });
  });
}
