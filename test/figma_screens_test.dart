import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'package:job_platform_mobile/core/services/file_picker_service.dart';
import 'support/fake_ai_repository.dart';
import 'package:job_platform_mobile/features/ai_copilot/presentation/ai_copilot_screen.dart';
import 'package:job_platform_mobile/features/ai_copilot/presentation/resume_scoring_screen.dart';
import 'package:job_platform_mobile/features/connections/presentation/connections_screen.dart';
import 'package:job_platform_mobile/features/jobs/presentation/saved_jobs_screen.dart';
import 'package:job_platform_mobile/features/recruiter/presentation/candidate_applications_screen.dart';
import 'package:job_platform_mobile/features/recruiter/presentation/post_job_screen.dart';
import 'package:job_platform_mobile/features/recruiter/presentation/recruiter_dashboard_screen.dart';
import 'package:job_platform_mobile/features/recruiter/presentation/recruiter_jobs_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Figma Screens Widget Tests', () {
    testWidgets('ConnectionsScreen renders 3 tabs and handles tab switching', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ConnectionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('NTD kết nối'), findsOneWidget);
      expect(find.text('Chờ phản hồi'), findsOneWidget);
      expect(find.text('Đã phản hồi'), findsOneWidget);
      expect(find.text('Quá hạn'), findsOneWidget);
      expect(find.text('Badoo Inc.'), findsOneWidget);

      // Switch to "Đã phản hồi" tab
      await tester.tap(find.text('Đã phản hồi'));
      await tester.pumpAndSettle();
      expect(find.text('FPT Software'), findsOneWidget);

      // Switch to "Quá hạn" tab
      await tester.tap(find.text('Quá hạn'));
      await tester.pumpAndSettle();
      expect(find.text('Netflix Inc.'), findsOneWidget);
    });

    testWidgets(
      'AiCopilotScreen renders greeting, suggestions, and sends a prompt',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(home: AiCopilotScreen(repository: FakeAiRepository())),
        );
        await tester.pumpAndSettle();

        expect(find.text('Trợ lý việc làm AI'), findsOneWidget);
        expect(find.text('Chào bạn 👋'), findsOneWidget);
        expect(find.text('Gợi ý việc làm'), findsOneWidget);
        expect(find.text('Cải thiện CV'), findsOneWidget);
        expect(find.text('Luyện phỏng vấn'), findsOneWidget);

        // Tap on a suggestion prompt
        await tester.tap(find.text('Gợi ý việc làm'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();

        expect(find.text('Phản hồi kiểm thử từ Gateway.'), findsOneWidget);
        expect(find.text('90% phù hợp'), findsNothing);
      },
    );

    testWidgets('ResumeScoringScreen renders score hero and skill feedback', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResumeScoringScreen(
            repository: FakeAiRepository(),
            jobId: 'actual-job',
            cvPickerService: MockCvPickerService(
              predefinedFile: SelectedCvFile(
                name: 'cv.pdf',
                size: 3,
                bytes: Uint8List.fromList([1, 2, 3]),
              ),
            ),
            targetJobTitle: 'UI/UX Designer',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mức độ phù hợp CV'), findsOneWidget);
      expect(find.text('82 / 100'), findsNothing);
      await tester.tap(find.byKey(const Key('scoring_choose_cv')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scoring_submit')));
      await tester.pumpAndSettle();
      expect(find.text('82 / 100'), findsOneWidget);
      expect(find.text('Kỹ năng phù hợp'), findsOneWidget);
      expect(find.text('Cần bổ sung'), findsOneWidget);
      expect(find.text('Ứng tuyển ngay'), findsOneWidget);
    });

    testWidgets('SavedJobsScreen renders saved jobs list and search input', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SavedJobsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Việc làm đã lưu'), findsOneWidget);
      expect(find.text('UI/UX Designer'), findsOneWidget);
      expect(find.text('Badoo Inc.'), findsOneWidget);

      // Filter via search
      await tester.enterText(find.byType(TextField), 'FPT');
      await tester.pumpAndSettle();

      expect(find.text('Senior Frontend Developer'), findsOneWidget);
      expect(find.text('UI/UX Designer'), findsNothing);
    });

    testWidgets('RecruiterDashboardScreen renders metrics and action tiles', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: RecruiterDashboardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tổng quan tuyển dụng'), findsOneWidget);
      expect(find.text('Chào nhà tuyển dụng'), findsOneWidget);
      expect(find.text('Tin đang mở'), findsOneWidget);
      expect(find.text('Hồ sơ mới'), findsOneWidget);
      expect(find.text('Quản lý tin tuyển dụng'), findsOneWidget);
      expect(find.text('Đăng tin mới'), findsOneWidget);
      expect(find.text('Hồ sơ ứng viên'), findsOneWidget);
    });

    testWidgets(
      'RecruiterJobsScreen renders postings and PostJobScreen renders form',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: RecruiterJobsScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Tin tuyển dụng của tôi'), findsOneWidget);
        expect(find.text('UI/UX Designer'), findsOneWidget);
        expect(find.text('Tạo tin mới'), findsOneWidget);

        await tester.pumpWidget(const MaterialApp(home: PostJobScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Đăng / sửa tin tuyển dụng'), findsOneWidget);
        expect(find.text('Tiêu đề vị trí'), findsOneWidget);
        expect(find.text('Xem trước & Xuất bản tin'), findsOneWidget);
      },
    );

    testWidgets(
      'CandidateApplicationsScreen renders candidate reviews and status update',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CandidateApplicationsScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hồ sơ ứng viên'), findsOneWidget);
        expect(find.text('Khoa Phạm'), findsOneWidget);
        expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
        expect(find.text('Xem hồ sơ Khoa Phạm'), findsOneWidget);

        // Open detail modal
        await tester.tap(find.text('Xem hồ sơ Khoa Phạm'));
        await tester.pumpAndSettle();

        expect(find.text('Cập nhật trạng thái ứng tuyển:'), findsOneWidget);
        expect(find.widgetWithText(ChoiceChip, 'Được nhận'), findsOneWidget);
      },
    );
  });
}
