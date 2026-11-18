import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_platform_mobile/core/session/auth_session.dart';
import 'package:job_platform_mobile/core/theme/app_theme.dart';
import 'package:job_platform_mobile/features/auth/domain/models/auth_result.dart';
import 'package:job_platform_mobile/features/auth/domain/models/user_model.dart';
import 'package:job_platform_mobile/features/jobs/data/repositories/mock_job_repository.dart';
import 'package:job_platform_mobile/features/jobs/domain/models/job_model.dart';
import 'package:job_platform_mobile/features/jobs/presentation/job_detail_screen.dart';
import 'package:job_platform_mobile/features/jobs/presentation/widgets/job_detail_bottom_bar.dart';

void main() {
  late MockJobRepository mockRepo;

  setUp(() {
    mockRepo = MockJobRepository();
    AuthSession.instance.clearSession();
  });

  testWidgets(
    'JobDetailScreen renders job info, metrics, and content correctly',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: JobDetailScreen(jobId: 'job-1', jobRepository: mockRepo),
        ),
      );

      // Initial pump: Shimmer loading
      expect(find.text('Chi tiết việc làm'), findsOneWidget);

      // Settle async fetch
      await tester.pumpAndSettle();

      // Verify Job info is displayed
      expect(
        find.text('Senior Flutter Developer (Cross-Platform)'),
        findsOneWidget,
      );
      expect(find.text('FPT Software'), findsWidgets);
      expect(find.text('Mô tả công việc'), findsOneWidget);
      expect(find.text('Yêu cầu ứng viên'), findsOneWidget);
      expect(find.text('Kỹ năng chuyên môn'), findsOneWidget);
      expect(find.text('Quyền lợi & Phúc lợi'), findsOneWidget);
      expect(find.text('Flutter'), findsWidgets);
      expect(find.text('Dart'), findsWidgets);

      // Verify Guest CTA button
      expect(find.text('Ứng tuyển ngay'), findsOneWidget);
    },
  );

  testWidgets(
    'JobDetailScreen shows recruiter CTA when logged in as recruiter',
    (tester) async {
      // Log in as recruiter
      AuthSession.instance.setSession(
        AuthResult(
          user: UserModel(
            id: 'recruiter-1',
            name: 'HR Manager',
            email: 'recruiter@fpt.com',
            role: UserRole.recruiter,
            createdAt: DateTime.now(),
          ),
          token: 'mock-recruiter-token',
          refreshToken: 'mock-refresh-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: JobDetailScreen(jobId: 'job-1', jobRepository: mockRepo),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Recruiter button is rendered
      expect(find.textContaining('Xem ứng viên'), findsOneWidget);
    },
  );

  testWidgets('JobDetailScreen shows error view when job is not found', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: JobDetailScreen(
          jobId: 'non-existent-job-id',
          jobRepository: mockRepo,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Không tìm thấy thông tin tin tuyển dụng này.'),
      findsOneWidget,
    );
    expect(find.text('Quay lại danh sách'), findsOneWidget);
  });

  testWidgets(
    'JobDetailBottomBar disables direct apply CTA for crawled sha256 jobs',
    (tester) async {
      final crawledJob = JobModel(
        id: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        title: 'External Mobile Dev',
        companyName: 'External Corp',
        location: 'Hà Nội',
        category: 'IT',
        description: 'Desc',
        requirements: 'Req',
        postedAt: DateTime(2026),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: JobDetailBottomBar(
              job: crawledJob,
              onShare: () {},
              onPrimaryAction: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tin tổng hợp ngoài hệ thống'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    },
  );
}
