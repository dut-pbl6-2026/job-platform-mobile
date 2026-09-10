import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/services/file_picker_service.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/applications/data/repositories/mock_application_repository.dart';
import 'package:job_platform_mobile/features/applications/presentation/apply_job_screen.dart';

void main() {
  late MockApplicationRepository mockRepo;
  late MockCvPickerService mockPicker;

  setUp(() {
    mockRepo = MockApplicationRepository();
    mockRepo.clear();
    mockPicker = MockCvPickerService();
  });

  testWidgets(
    'ApplyJobScreen renders job info, contact info, and file upload zone (MOB-01-04)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ApplyJobScreen(
            jobId: 'job-fresh-1',
            jobTitle: 'Senior Flutter Developer',
            companyName: 'FPT Software',
            applicationRepository: mockRepo,
            cvPickerService: mockPicker,
          ),
        ),
      );

      // Verify Title & Job info
      expect(find.text('Ứng tuyển việc làm'), findsOneWidget);
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
      expect(find.text('FPT Software'), findsOneWidget);

      // Verify Contact Info Section
      expect(find.text('Thông tin liên hệ ứng viên'), findsOneWidget);

      // Verify Upload Zone
      expect(find.text('Chọn file CV từ thiết bị'), findsOneWidget);
      expect(find.text('Thư giới thiệu (Cover letter)'), findsOneWidget);
      expect(find.text('Nộp hồ sơ ứng tuyển'), findsOneWidget);
    },
  );

  testWidgets(
    'ApplyJobScreen shows validation error if submitting without selecting CV',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ApplyJobScreen(
            jobId: 'job-fresh-2',
            jobTitle: 'Senior Flutter Developer',
            companyName: 'FPT Software',
            applicationRepository: mockRepo,
            cvPickerService: mockPicker,
          ),
        ),
      );

      // Ensure submit button is visible and tap it
      final submitButton = find.text('Nộp hồ sơ ứng tuyển');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(
        find.text('Vui lòng tải lên file CV (PDF, DOC, DOCX) của bạn.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ApplyJobScreen picks CV, adds cover letter suggestion, and submits successfully',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ApplyJobScreen(
            jobId: 'job-fresh-3',
            jobTitle: 'Senior Flutter Developer',
            companyName: 'FPT Software',
            applicationRepository: mockRepo,
            cvPickerService: mockPicker,
          ),
        ),
      );

      // Tap CV Picker to choose file
      final pickerFinder = find.text('Chọn file CV từ thiết bị');
      await tester.ensureVisible(pickerFinder);
      await tester.tap(pickerFinder);
      await tester.pumpAndSettle();

      // Verify selected CV file is displayed
      expect(find.text('Nguyen_Van_A_CV_Flutter_2026.pdf'), findsOneWidget);

      // Tap suggestion chip to append to cover letter
      final suggestionFinder = find.text('Tôi có 4+ năm kinh nghiệm Flutter');
      await tester.ensureVisible(suggestionFinder);
      await tester.tap(suggestionFinder);
      await tester.pumpAndSettle();

      // Tap submit button
      final submitFinder = find.text('Nộp hồ sơ ứng tuyển');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump(); // Start submission
      await tester.pump(
        const Duration(milliseconds: 700),
      ); // Advance past mock network delay
      await tester.pumpAndSettle(); // Settle dialog animation

      // Verify Success Dialog is displayed
      expect(find.text('Ứng tuyển thành công!'), findsOneWidget);
      expect(find.text('Xem lịch sử ứng tuyển'), findsOneWidget);
    },
  );
}
