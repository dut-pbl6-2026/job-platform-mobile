import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/features/applications/domain/models/application_model.dart';

void main() {
  group('ApplicationStatus Tests', () {
    test('fromString parses valid status strings correctly', () {
      expect(
        ApplicationStatus.fromString('pending'),
        ApplicationStatus.pending,
      );
      expect(
        ApplicationStatus.fromString('reviewed'),
        ApplicationStatus.reviewed,
      );
      expect(
        ApplicationStatus.fromString('shortlisted'),
        ApplicationStatus.shortlisted,
      );
      expect(
        ApplicationStatus.fromString('accepted'),
        ApplicationStatus.accepted,
      );
      expect(
        ApplicationStatus.fromString('rejected'),
        ApplicationStatus.rejected,
      );
      expect(
        ApplicationStatus.fromString('Chờ duyệt'),
        ApplicationStatus.pending,
      );
      expect(
        ApplicationStatus.fromString('UNKNOWN'),
        ApplicationStatus.pending,
      );
    });

    test('displayName and properties are localized in Vietnamese', () {
      expect(ApplicationStatus.pending.displayName, 'Chờ duyệt');
      expect(ApplicationStatus.reviewed.displayName, 'Đã xem');
      expect(ApplicationStatus.shortlisted.displayName, 'Phù hợp');
      expect(ApplicationStatus.accepted.displayName, 'Trúng tuyển');
      expect(ApplicationStatus.rejected.displayName, 'Từ chối');

      for (final status in ApplicationStatus.values) {
        expect(status.description.isNotEmpty, true);
        expect(status.color, isNotNull);
        expect(status.backgroundColor, isNotNull);
        expect(status.icon, isNotNull);
      }
    });
  });

  group('ApplicationStatusHistoryItem Tests', () {
    test('Serialization to/from JSON works symmetrically', () {
      final now = DateTime(2026, 9, 8, 14, 30);
      final item = ApplicationStatusHistoryItem(
        status: ApplicationStatus.reviewed,
        note: 'HR đã xem xét hồ sơ.',
        changedAt: now,
        changedBy: 'HR Lead',
      );

      final json = item.toJson();
      expect(json['status'], 'reviewed');
      expect(json['note'], 'HR đã xem xét hồ sơ.');
      expect(json['changedBy'], 'HR Lead');

      final deserialized = ApplicationStatusHistoryItem.fromJson(json);
      expect(deserialized.status, ApplicationStatus.reviewed);
      expect(deserialized.note, item.note);
      expect(deserialized.changedBy, item.changedBy);
      expect(deserialized.changedAt, now);
    });
  });

  group('ApplicationModel Tests', () {
    test(
      'ApplicationModel JSON serialization and copyWith works as expected',
      () {
        final now = DateTime(2026, 9, 8, 10, 0);
        final app = ApplicationModel(
          id: 'app-101',
          jobId: 'job-101',
          jobTitle: 'Senior Flutter Developer',
          companyName: 'FPT Software',
          applicantId: 'usr-01',
          applicantName: 'Nguyễn Văn An',
          applicantEmail: 'an.nguyen@example.com',
          cvUrl: 'https://r2.jobplatform.vn/cvs/cv.pdf',
          cvFileName: 'Nguyen_Van_An_CV.pdf',
          cvFileSize: 400 * 1024,
          status: ApplicationStatus.pending,
          createdAt: now,
          updatedAt: now,
          coverLetter: 'Thư xin việc ngắn',
          statusHistory: [
            ApplicationStatusHistoryItem(
              status: ApplicationStatus.pending,
              note: 'Hồ sơ đã nộp.',
              changedAt: now,
            ),
          ],
        );

        final json = app.toJson();
        expect(json['id'], 'app-101');
        expect(json['status'], 'pending');

        final deserialized = ApplicationModel.fromJson(json);
        expect(deserialized.id, 'app-101');
        expect(deserialized.jobTitle, 'Senior Flutter Developer');
        expect(deserialized.companyName, 'FPT Software');
        expect(deserialized.status, ApplicationStatus.pending);
        expect(deserialized.statusHistory.length, 1);

        // copyWith test
        final updated = app.copyWith(status: ApplicationStatus.shortlisted);
        expect(updated.status, ApplicationStatus.shortlisted);
        expect(updated.id, app.id);
      },
    );

    test('fromJson ignores snake_case fields outside fromCreatedJson', () {
      final parsed = ApplicationModel.fromJson({
        'id': 'app-202',
        'job_id': 'job-snake',
        'job_title': 'Snake Title',
        'company_name': 'Snake Corp',
        'applicant_id': 'usr-snake',
        'cv_url': '/api/applications/cv/snake.pdf',
      });

      expect(parsed.id, 'app-202');
      expect(parsed.jobId, isEmpty);
      expect(parsed.jobTitle, 'Vị trí tuyển dụng');
      expect(parsed.companyName, 'Doanh nghiệp');
      expect(parsed.cvUrl, isEmpty);
    });

    test(
      'fromCreatedJson adapts POST /api/applications 201 payload with ApplyJobParams',
      () {
        const params = ApplyJobParams(
          jobId: 'job-guid-1',
          jobTitle: 'Backend Engineer',
          companyName: 'FPT Software',
          coverLetter: 'Excited to apply',
          cvFileName: 'resume.pdf',
          cvFileSize: 1024,
        );
        final created = ApplicationModel.fromCreatedJson({
          'id': 'app-303',
          'job_id': 'job-guid-1',
          'applicant_id': 'usr-9',
          'status': 'Pending',
          'cv_url': '/api/applications/cv/resume.pdf',
        }, params: params);

        expect(created.id, 'app-303');
        expect(created.jobId, 'job-guid-1');
        expect(created.applicantId, 'usr-9');
        expect(created.jobTitle, 'Backend Engineer');
        expect(created.companyName, 'FPT Software');
        expect(created.cvUrl, '/api/applications/cv/resume.pdf');
        expect(created.cvFileName, 'resume.pdf');
        expect(created.status, ApplicationStatus.pending);
      },
    );
  });
}
