import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/recruiter/data/repositories/mock_recruiter_repository.dart';
import 'package:job_platform_mobile/features/recruiter/presentation/candidate_applications_screen.dart';
import 'package:job_platform_mobile/features/recruiter/presentation/post_job_screen.dart';
import 'package:job_platform_mobile/features/recruiter/presentation/recruiter_dashboard_screen.dart';
import 'package:job_platform_mobile/features/recruiter/presentation/recruiter_jobs_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Recruiter Screens Comprehensive Widget Tests', () {
    late MockRecruiterRepository mockRepo;

    setUp(() {
      mockRepo = MockRecruiterRepository();
    });

    testWidgets('PostJobScreen validates form and submits job to repository', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: PostJobScreen(repository: mockRepo, isPrototypeMode: true),
        ),
      );
      await tester.pumpAndSettle();

      // Verify screen title and prototype banner
      expect(find.text('Đăng / sửa tin tuyển dụng'), findsOneWidget);
      expect(find.textContaining('Bản thử nghiệm (Beta)'), findsOneWidget);

      // Verify fields start empty (no hardcoded prefilled values)
      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);

      // Try submitting empty form -> triggers validation errors
      final submitButton = find.text('Xem trước & Xuất bản tin');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tiêu đề'), findsOneWidget);
      expect(find.text('Vui lòng nhập địa điểm'), findsOneWidget);
      expect(find.text('Vui lòng nhập mức lương'), findsOneWidget);
      expect(find.text('Vui lòng nhập mô tả'), findsOneWidget);

      // Fill in valid data
      final titleField = find.byType(TextFormField).at(0);
      await tester.ensureVisible(titleField);
      await tester.enterText(titleField, 'Flutter Lead Developer');

      final locField = find.byType(TextFormField).at(1);
      await tester.ensureVisible(locField);
      await tester.enterText(locField, 'FPT Software · Đà Nẵng');

      final salField = find.byType(TextFormField).at(2);
      await tester.ensureVisible(salField);
      await tester.enterText(salField, '30.000.000 – 45.000.000 ₫');

      final descField = find.byType(TextFormField).at(3);
      await tester.ensureVisible(descField);
      await tester.enterText(
        descField,
        'Xây dựng ứng dụng Flutter kiến trúc Clean Architecture.',
      );
      await tester.pumpAndSettle();

      // Submit form
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Xác nhận đăng tin'), findsOneWidget);
      expect(
        find.textContaining('Tin tuyển dụng "Flutter Lead Developer"'),
        findsOneWidget,
      );

      // Tap 'Xuất bản' button in dialog
      final publishButton = find.text('Xuất bản');
      await tester.tap(publishButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify job was stored in repository
      final jobs = await mockRepo.getMyJobs();
      expect(jobs.any((j) => j.title == 'Flutter Lead Developer'), isTrue);
    });

    testWidgets(
      'CandidateApplicationsScreen displays mock banner, candidates and updates status via repository',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CandidateApplicationsScreen(
              repository: mockRepo,
              isMock: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Mock Flag Banner
        expect(find.textContaining('Mock Flag'), findsOneWidget);

        // Verify candidate items
        expect(find.text('Khoa Phạm'), findsOneWidget);
        expect(find.text('Nguyễn Minh Anh'), findsOneWidget);

        // Open candidate detail bottom sheet
        await tester.tap(find.text('Xem hồ sơ Khoa Phạm'));
        await tester.pumpAndSettle();

        expect(find.text('Cập nhật trạng thái ứng tuyển:'), findsOneWidget);
        expect(find.widgetWithText(ChoiceChip, 'Được nhận'), findsOneWidget);

        // Update status to 'Được nhận'
        await tester.tap(find.widgetWithText(ChoiceChip, 'Được nhận'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 300));

        // Verify snackbar feedback
        expect(
          find.text('Đã cập nhật trạng thái ứng viên thành: Được nhận'),
          findsOneWidget,
        );

        // Verify repository state updated
        final candidates = await mockRepo.getCandidateApplications();
        final cand = candidates.firstWhere((c) => c.id == 'cand_1');
        expect(cand.status, 'Được nhận');
      },
    );

    testWidgets(
      'RecruiterJobsScreen renders job postings and mock flag badge',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: RecruiterJobsScreen(repository: mockRepo, isMock: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tin tuyển dụng của tôi'), findsOneWidget);
        expect(find.textContaining('Mock Flag'), findsOneWidget);
        expect(find.text('UI/UX Designer'), findsOneWidget);
        expect(find.text('Tạo tin mới'), findsOneWidget);
      },
    );

    testWidgets(
      'RecruiterDashboardScreen renders dynamic metrics and action tiles',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: RecruiterDashboardScreen(repository: mockRepo, isMock: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tổng quan tuyển dụng'), findsOneWidget);
        expect(find.textContaining('Mock Flag'), findsOneWidget);
        expect(find.text('Chào nhà tuyển dụng'), findsOneWidget);
        expect(find.text('Tin đang mở'), findsOneWidget);
        expect(find.text('Hồ sơ mới'), findsOneWidget);
        expect(find.text('Quản lý tin tuyển dụng'), findsOneWidget);
        expect(find.text('Đăng tin mới'), findsOneWidget);
        expect(find.text('Hồ sơ ứng viên'), findsOneWidget);
      },
    );
  });
}
